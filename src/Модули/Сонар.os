///////////////////////////////////////////////////////////////////
//
// Модуль с набором методов работы с SonarQube
// Используются методы rest-api sonarqube
// (C) TheShadowCo
//
///////////////////////////////////////////////////////////////////

Перем МаксимальныйРазмерПорцииДанных;

///////////////////////////////////////////////////////////////////
// Программный интерфейс
///////////////////////////////////////////////////////////////////

// ПолучитьПроекты
//	Возвращает набор проектов
// Параметры:
//  АдресСервера  - Строка - Адрес (хост) сервера SonarQube
//  Токен  - Строка - Токен пользователя, от имени которого выполняются запросы к API
//
// Возвращаемое значение:
//   Соответствие   - Коллекция проектов
//		* Ключ - Строка - Код (Ключ) проекта
//		* Значение - Структура - Описание проекта
//			** Идентификатор - Строка - Идентификатор проекта
//			** Код - Строка - Код (Ключ) проекта
//
Функция ПолучитьПроекты(АдресСервера, Токен) Экспорт
	
	URLШаблон = "components/search?qualifiers=TRK&ps=500&p=%1";
	НомерСтраницы = 1;
	Проекты = Новый Соответствие();
	
	Пока Истина Цикл
		
		URL = СтрШаблон(URLШаблон, Формат(НомерСтраницы, "ЧГ="));
		Ответ = ВыполнитьЗапрос(АдресСервера, Токен, URL, "GET");
		
		Для Каждого ОписаниеПроекта Из Ответ.components Цикл
			
			НовыйПроект = Новый Структура();
			НовыйПроект.Вставить("Идентификатор", ОписаниеПроекта.id);
			НовыйПроект.Вставить("Код", ОписаниеПроекта.key);
			Проекты.Вставить(НовыйПроект.Код, НовыйПроект);
			
		КонецЦикла;
		
		Если БольшеНетДанных(Ответ) Тогда
			Прервать;
		КонецЕсли;
		
		НомерСтраницы = НомерСтраницы + 1;
		
	КонецЦикла;
	
	Возврат Проекты;
	
КонецФункции

// ПолучитьЗамечанияПроекта
//	Возвращает набор замечаний проекта по установленным отборам
// Параметры:
//  АдресСервера  - Строка - Адрес (хост) сервера SonarQube
//  Токен  - Строка - Токен пользователя, от имени которого выполняются запросы к API
//  ОписаниеПроекта  - Структура - Описание проекта SonarQube
//		* Идентификатор - Строка - Идентификатор проекта
//		* Код - Строка - Код (Ключ) проекта
//  СтатусыСтрокой - Строка - Строка с идентификаторами статусов замечаний
//  ИзEDTВКонфигуратор - Булево - Признак необходимости преобразования замечаний между родительским проектом и дочерними
//
// Возвращаемое значение:
//   Соответствие   - Коллекция замечаний
//		* Ключ - Строка - Относительный путь к файлу, в котором зафиксировано замечание
//		* Значение - Структура - Описание проекта
//			** ПутьКФайлу - Строка -  Относительный путь к файлу, в котором зафиксировано замечание
//			** Правила - Соответствие - Набор правил с замечаниями
//				*** Ключ - Строка - ключ правила
//				*** Значение - Структура - Описание правила
//					**** Правило - Строка - Ключ правила
//					**** Ошибки - Соответствие - Набор зарегистрированных замечаний (ошибок)
//						***** Ключ - Строка - Хэш замечания
//						***** Значение - Структура - Описание замечания
//							****** Код - Строка - Ключ замечания
//							****** Хэш - Строка - Хэш замечания
//							****** Количество - Число - Количество закрываемых замечаний
//							****** КоличествоВсего - Число - Общее количество замечаний с данным хэшем
//
Функция ПолучитьЗамечанияПроекта(АдресСервера, Токен, ОписаниеПроекта, СтатусыСтрокой, ИзEDTВКонфигуратор) Экспорт
	
	КлючиКомпонентов = ПолучитьКлючиКомпонентов(АдресСервера, Токен, ОписаниеПроекта.Код, СтатусыСтрокой);
	Замечания = Новый Соответствие();
	URLШаблон = "issues/search?ps=500&componentKeys=%1%2";
	Если Не ПустаяСтрока(СтатусыСтрокой) Тогда
		URLШаблон = URLШаблон + "&statuses=" + СтатусыСтрокой;		
	КонецЕсли;
	URLШаблон = URLШаблон + "&p=";
	
	КоличествоКомпонентов = КлючиКомпонентов.Количество();
	Для Ит = 0 По КоличествоКомпонентов - 1 Цикл
		КлючКомпонента = КлючиКомпонентов[Ит];
		
		НомерСтраницы = 1;
		URL = СтрШаблон(URLШаблон, КлючКомпонента, "");
		Пока Истина Цикл
			
			Ответ = ВыполнитьЗапрос(АдресСервера, Токен, URL + Формат(НомерСтраницы, "ЧГ="), "GET");
			Если Ответ.total > МаксимальныйРазмерПорцииДанных Тогда
				// прочитаем компоненты, перенесем их в общий список, а по текущем прочтем только те, что висят именно на нем
				КлючиДочернихКомпонентов = ПолучитьКлючиКомпонентов(АдресСервера, Токен, КлючКомпонента, СтатусыСтрокой, Ложь);
				Для Каждого КлючДочернегоКомпонента Из КлючиДочернихКомпонентов Цикл
					КлючиКомпонентов.Добавить(КлючДочернегоКомпонента);
				КонецЦикла;
				КоличествоКомпонентов = КлючиКомпонентов.Количество();
				URL = СтрШаблон(URLШаблон, КлючКомпонента, "&onComponentOnly=true");
				Ответ = ВыполнитьЗапрос(АдресСервера, Токен, URL + Формат(НомерСтраницы, "ЧГ="), "GET");
			КонецЕсли;
			
			Для Каждого ОписаниеОшибки Из Ответ.issues Цикл
				
				ПутьКФайлу = СтрЗаменить(ОписаниеОшибки.component, ОписаниеПроекта.Код + ":", "");
				
				Если ИзEDTВКонфигуратор Тогда
					ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "configuration/src/", "src/configuration/");
					ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/ManagerModule.bsl", "/Ext/ManagerModule.bsl");
					ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/ObjectModule.bsl", "/Ext/ObjectModule.bsl");
					ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/CommandModule.bsl", "/Ext/CommandModule.bsl");
					ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/ValueManagerModule.bsl", "/Ext/ValueManagerModule.bsl");
					ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/configuration/Configuration", "/configuration/Ext");
					Если СтрНайти(ПутьКФайлу, "Forms") Тогда
						ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/Module.bsl", "/Ext/Form/Module.bsl");
					Иначе
						ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/Module.bsl", "/Ext/Module.bsl");
					КонецЕсли;
				КонецЕсли;
				
				НовоеОписаниеОшибки = Новый Структура();
				НовоеОписаниеОшибки.Вставить("Код", ОписаниеОшибки.key);
				НовоеОписаниеОшибки.Вставить("Количество", 1);
				НовоеОписаниеОшибки.Вставить("КоличествоВсего", 1);
				Хэш = ПолучитьХэшЗамечания(ОписаниеОшибки);
				НовоеОписаниеОшибки.Вставить("Хэш", Хэш);
				
				ТекущийМодуль = Замечания.Получить(ПутьКФайлу);
				Если ТекущийМодуль = Неопределено Тогда 
					ТекущийМодуль = Новый Структура("ПутьКФайлу, Правила, Ключ", ПутьКФайлу, Новый Соответствие(), ОписаниеОшибки.component);
				КонецЕсли;
				ТекущееПравило = ТекущийМодуль.Правила.Получить(ОписаниеОшибки.rule);
				Если ТекущееПравило = Неопределено Тогда
					ТекущееПравило = Новый Структура("Правило, Ошибки", ОписаниеОшибки.rule, Новый Соответствие());
				КонецЕсли;
				
				ТекущаяОшибка = ТекущееПравило.Ошибки.Получить(Хэш);
				Если ТекущаяОшибка = Неопределено Тогда
					ТекущаяОшибка = НовоеОписаниеОшибки;
				Иначе
					ТекущаяОшибка.Количество = ТекущаяОшибка.Количество + 1;
					ТекущаяОшибка.КоличествоВсего = ТекущаяОшибка.КоличествоВсего + 1;
				КонецЕсли;
				
				ТекущееПравило.Ошибки.Вставить(ТекущаяОшибка.Хэш, ТекущаяОшибка);
				ТекущийМодуль.Правила.Вставить(ТекущееПравило.Правило, ТекущееПравило);
				Замечания.Вставить(ПутьКФайлу, ТекущийМодуль);
				
			КонецЦикла;
			
			Если БольшеНетДанных(Ответ) Тогда
				Прервать;
			КонецЕсли;
			
			НомерСтраницы = НомерСтраницы + 1;
			
		КонецЦикла;
		
	КонецЦикла;
	Возврат Замечания;
	
КонецФункции

// ЗаполнитьКоличествоОдинаковыхЗамечанийПроекта
//	По сформированному набору замечаний дополняет общее количество замечаний со всеми статусами с тем же хэшем
// Параметры:
//  АдресСервера  - Строка - Адрес (хост) сервера SonarQube
//  Токен  - Строка - Токен пользователя, от имени которого выполняются запросы к API
//  ЗамечанияРодительскогоПроекта - Соответствие - Замечания для закрытия из родительского проекта. См. ПолучитьЗамечанияПроекта
//
Процедура ЗаполнитьКоличествоОдинаковыхЗамечанийПроекта(АдресСервера, Токен, ЗамечанияРодительскогоПроекта) Экспорт
	
	URLШаблон = "issues/search?componentKeys=%1&rules=%2&ps=500&p=";
	Для Каждого Файл Из ЗамечанияРодительскогоПроекта Цикл
		Для Каждого Правило Из Файл.Значение.Правила Цикл
			Для Каждого Замечание Из Правило.Значение.Ошибки Цикл
				Замечание.Значение.КоличествоВсего = 0;
			КонецЦикла;
			
			URL = СтрШаблон(URLШаблон, Файл.Значение.Ключ, Правило.Значение.Правило);
			НомерСтраницы = 1;
			
			Пока Истина Цикл
				Ответ = ВыполнитьЗапрос(АдресСервера, Токен, URL + Формат(НомерСтраницы, "ЧГ="), "GET");
				Для Каждого ОписаниеОшибки Из Ответ.issues Цикл
					Хэш = ПолучитьХэшЗамечания(ОписаниеОшибки);
					ТекущаяОшибка = Правило.Значение.Ошибки.Получить(Хэш);
					Если ТекущаяОшибка = Неопределено Тогда
						Продолжить;
					КонецЕсли;
					
					ТекущаяОшибка.КоличествоВсего = ТекущаяОшибка.КоличествоВсего + 1;
					
				КонецЦикла;
				
				Если БольшеНетДанных(Ответ) Тогда
					Прервать;
				КонецЕсли;
				
				НомерСтраницы = НомерСтраницы + 1;
				
			КонецЦикла;
		КонецЦикла;
	КонецЦикла;
	
КонецПроцедуры

// ПолучитьЗакрываемыеЗамечания
//	Возвращает набор открытых замечаний проекта, которые необходимо закрыть
// Параметры:
//  АдресСервера  - Строка - Адрес (хост) сервера SonarQube
//  Токен  - Строка - Токен пользователя, от имени которого выполняются запросы к API
//  ОписаниеПроекта  - Структура - Описание проекта SonarQube
//		* Идентификатор - Строка - Идентификатор проекта
//		* Код - Строка - Код (Ключ) проекта
//  ЗамечанияРодительскогоПроекта - Соответствие - Замечания для закрытия из родительского проекта. См. ПолучитьЗамечанияПроекта
//
// Возвращаемое значение:
//   Массив - ключи закрываемых замечаний
//
Функция ПолучитьЗакрываемыеЗамечания(АдресСервера, Токен, ОписаниеПроекта, ЗамечанияРодительскогоПроекта) Экспорт
	
	Замечания = Новый Соответствие();
	Статусы = СтрРазделить("OPEN,CONFIRMED,REOPENED", ",", Ложь);
	
	URLШаблон = "issues/search?componentKeys=%1&rules=%2&ps=500&p=";
	Для Каждого Файл Из ЗамечанияРодительскогоПроекта Цикл
		Для Каждого Правило Из Файл.Значение.Правила Цикл
			URL = СтрШаблон(URLШаблон, ОписаниеПроекта.Код + ":" + Файл.Значение.ПутьКФайлу, Правило.Значение.Правило);
			НомерСтраницы = 1;
			
			Пока Истина Цикл
				Ответ = ВыполнитьЗапрос(АдресСервера, Токен, URL + Формат(НомерСтраницы, "ЧГ="), "GET");
				Для Каждого ОписаниеОшибки Из Ответ.issues Цикл
					Хэш = ПолучитьХэшЗамечания(ОписаниеОшибки);
					РодительскоеЗамечание = Правило.Значение.Ошибки.Получить(Хэш);
					Если РодительскоеЗамечание = Неопределено Тогда
						Продолжить;
					КонецЕсли;
					
					КлючОшибки = ОписаниеОшибки.component + Хэш;
					ПутьКФайлу = СтрЗаменить(ОписаниеОшибки.component, ОписаниеПроекта.Код + ":", "");
					ТекущаяОшибка = Замечания.Получить(КлючОшибки);
					Если ТекущаяОшибка = Неопределено Тогда
						ТекущаяОшибка = Новый Структура();
						ТекущаяОшибка.Вставить("КоличествоВсего", 0);
						ТекущаяОшибка.Вставить("Количество", 0);
						ТекущаяОшибка.Вставить("РодительскоеЗамечание", РодительскоеЗамечание);
						ТекущаяОшибка.Вставить("Ключи", Новый Массив());
					КонецЕсли;
					
					ТекущаяОшибка.КоличествоВсего = ТекущаяОшибка.КоличествоВсего + 1;
					Если Статусы.Найти(ОписаниеОшибки.status) <> Неопределено Тогда
						ТекущаяОшибка.Количество = ТекущаяОшибка.Количество + 1;
						ТекущаяОшибка.Ключи.Добавить(ОписаниеОшибки.key);
					КонецЕсли;
					
					Замечания.Вставить(КлючОшибки, ТекущаяОшибка);
					
				КонецЦикла;
				
				Если БольшеНетДанных(Ответ) Тогда
					Прервать;
				КонецЕсли;
				
				НомерСтраницы = НомерСтраницы + 1;
				
			КонецЦикла;
		КонецЦикла;
	КонецЦикла;	
	
	ЗамечанияДляОбработки = Новый Массив();
	Для Каждого Замечание Из Замечания Цикл
		Если Замечание.Значение.КоличествоВсего <> Замечание.Значение.РодительскоеЗамечание.КоличествоВсего Тогда
			Продолжить;
		КонецЕсли;
		
		МожноЗакрыть = Замечание.Значение.Количество - Замечание.Значение.РодительскоеЗамечание.КоличествоВсего + Замечание.Значение.РодительскоеЗамечание.Количество;
		Для Ит = 0 По МожноЗакрыть - 1 Цикл
			ЗамечанияДляОбработки.Добавить(Замечание.Значение.Ключи[Ит]);
		КонецЦикла;
	КонецЦикла;
	
	Возврат ЗамечанияДляОбработки;
	
КонецФункции

// ЗакрытьЗамечания
//	Выполняет закрытие замечаний: устанавливает признак "WONTFIX" со ссылкой на родительский проект
// Параметры:
//  АдресСервера  - Строка - Адрес (хост) сервера SonarQube
//  Токен  - Строка - Токен пользователя, от имени которого выполняются запросы к API
//  ЗакрываемыеЗамечания - Массив - Ключи замечаний для закрытия
//  Комментарий - Строка - Текстовое сообщение, которое будет добавлено как коментарий к закрываемому замечанию
//  Теги - Строка - Список тегов, разделенных запятой, которые будут добавлены к закрываемым замечаниям.
//
Процедура ЗакрытьЗамечания(АдресСервера, Токен, ЗакрываемыеЗамечания, Комментарий, Теги = "") Экспорт
	
	URL = СтрШаблон("issues/bulk_change?do_transition=wontfix&comment=%1&issues=", Комментарий);
	URLДобавленияТегов = СтрШаблон("issues/bulk_change?add_tags=%1&issues=", Теги);
	
	ЗамечанияДляОбработки = Новый Массив();
	Для Каждого Замечание Из ЗакрываемыеЗамечания Цикл
		
		Если ЗамечанияДляОбработки.Количество() = 100 Тогда
			// Сначала отдельно устанавливаем теги, так как если это делать одновременно с закрытием замечаний,
			// то теги не устанавливаются.
			КлючиЗамечаний = СтрСоединить(ЗамечанияДляОбработки, ",");
			ВыполнитьЗапрос(АдресСервера, Токен, URLДобавленияТегов + КлючиЗамечаний, "POST");
			ВыполнитьЗапрос(АдресСервера, Токен, URL + КлючиЗамечаний, "POST");
			ЗамечанияДляОбработки.Очистить();
		КонецЕсли;
		
		ЗамечанияДляОбработки.Добавить(Замечание);
		
	КонецЦикла;
	
	Если ЗамечанияДляОбработки.Количество() Тогда
		КлючиЗамечаний = СтрСоединить(ЗамечанияДляОбработки, ",");
		ВыполнитьЗапрос(АдресСервера, Токен, URLДобавленияТегов + КлючиЗамечаний, "POST");
		ВыполнитьЗапрос(АдресСервера, Токен, URL + КлючиЗамечаний, "POST");
	КонецЕсли;
	
КонецПроцедуры

// ПолучитьМетрикиПроекта
//	Возвращает набор метрик проекта
// Параметры:
//  АдресСервера  - Строка - Адрес (хост) сервера SonarQube
//  Токен  - Строка - Токен пользователя, от имени которого выполняются запросы к API
//  ОписаниеПроекта  - Структура - Описание проекта SonarQube
//		* Идентификатор - Строка - Идентификатор проекта
//		* Код - Строка - Код (Ключ) проекта
//  ТребуемыеМетрики - Структура - Метрики, которые необходимо получить
//
// Возвращаемое значение:
//   Структура - Метрики и их значения
//
Функция ПолучитьМетрикиПроекта(АдресСервера, Токен, ОписаниеПроекта, Знач ТребуемыеМетрики) Экспорт
	
	МетрикиСтрокой = "";
	Для Каждого Метрика Из ТребуемыеМетрики Цикл
		МетрикиСтрокой = МетрикиСтрокой + ?(ПустаяСтрока(МетрикиСтрокой), "", ",") + Метрика.Ключ;
	КонецЦикла;
	
	Метрики = Новый Структура();
	ДоступныеМетрики = ДоступныеМетрики();
	
	URL = "measures/component?metricKeys=" + МетрикиСтрокой + "&component=" + ОписаниеПроекта.Код;
	Ответ = ВыполнитьЗапрос(АдресСервера, Токен, URL, "GET");
	
	Для Каждого Метрика Из Ответ.component.measures Цикл
		
		ЗначениеМетрики = "";
		Если Метрика.Свойство("value") Тогда
			ЗначениеМетрики = Метрика.value;
		ИначеЕсли Метрика.Свойство("periods") И Метрика.periods.Количество() Тогда 
			ЗначениеМетрики = Метрика.periods[0].value;
		Иначе
			Сообщить(Метрика.metric);
			Продолжить;
		КонецЕсли;
		
		Метрики.Вставить(СтрЗаменить(ДоступныеМетрики[Метрика.metric], " ", "_"), ЗначениеМетрики);
		Метрики.Вставить(Метрика.metric, ЗначениеМетрики);
		
	КонецЦикла;
	
	Для Каждого ТребуемаяМетрика Из ТребуемыеМетрики Цикл
		Если Не Метрики.Свойство(ТребуемаяМетрика.Ключ) Тогда
			Метрики.Вставить(СтрЗаменить(ДоступныеМетрики[ТребуемаяМетрика.Ключ], " ", "_"), null);
			Метрики.Вставить(ТребуемаяМетрика.Ключ, null);
		КонецЕсли;
	КонецЦикла;	
	
	Возврат Метрики;
	
КонецФункции

// ДоступныеМетрики
//	Возвращает коллекцию доступных метрик проекта
//  Возвращаемое значение:
//   Структура - Коллекция имен метрик
//
Функция ДоступныеМетрики() Экспорт
	
	Результат = Новый Структура();
	Результат.Вставить("bugs", "Ошибки");
	Результат.Вставить("new_bugs", "Ошибки в новом коде");
	Результат.Вставить("violations", "Замечания");
	Результат.Вставить("new_violations", "Замечания в новом коде");
	Результат.Вставить("ncloc", "Строки кода");
	Результат.Вставить("alert_status", "Порог качества"); // OK ERROR WARRING
	Результат.Вставить("security_rating", "Рейтинг безопасности"); // A B C D E числами
	Результат.Вставить("reliability_rating", "Рейтинг надежности"); // A B C D E числами
	Результат.Вставить("sqale_index", "Технический долг"); // в мин
	Результат.Вставить("open_issues", "Открытые замечания");
	Результат.Вставить("reopened_issues", "Переоткрытые замечания");
	Результат.Вставить("wont_fix_issues", "Неактуальные замечания");
	Результат.Вставить("false_positive_issues", "Ложное срабатывание");
	Результат.Вставить("cognitive_complexity", "Когнитивная сложность");
	Результат.Вставить("complexity", "Цикломатическая сложность");
	Результат.Вставить("confirmed_issues", "Подтвержденные замечания");
	Результат.Вставить("blocker_violations", "Блокирующие замечания");
	Результат.Вставить("new_blocker_violations", "Блокирующие замечания в новом коде");
	Результат.Вставить("critical_violations", "Критические замечания");
	Результат.Вставить("new_critical_violations", "Критические замечания в новом коде");
	Результат.Вставить("info_violations", "Информационные замечания");
	Результат.Вставить("new_info_violations", "Информационные замечания в новом коде");
	Результат.Вставить("major_violations", "Важные замечания");
	Результат.Вставить("new_major_violations", "Важные замечания в новом коде");
	Результат.Вставить("minor_violations", "Незначительные замечания");
	Результат.Вставить("new_minor_violations", "Незначительные замечания в новом коде");
	Результат.Вставить("duplicated_blocks", "Дублирующиеся участки кода");
	Результат.Вставить("new_duplicated_blocks", "Дублирующиеся участки в новом коде");
	
	Возврат Результат;
	
КонецФункции

///////////////////////////////////////////////////////////////////
// Слубные процедуры и функции
///////////////////////////////////////////////////////////////////

Функция БольшеНетДанных(ОтветСервера)
	
	Возврат ОтветСервера.paging.pageSize * ОтветСервера.paging.pageIndex >= ОтветСервера.paging.total;
	
КонецФункции

Функция ПолучитьХэшЗамечания(ОписаниеОшибки)
	
	Хэш = ОписаниеОшибки.rule;
	Если ОписаниеОшибки.Свойство("hash") Тогда
		Возврат Хэш + ОписаниеОшибки.hash + ?(ОписаниеОшибки.Свойство("line"), ОписаниеОшибки.line, "");
	Иначе
		Возврат Хэш + ?(ОписаниеОшибки.Свойство("textRange"), 
		"" + ОписаниеОшибки.textRange.startLine + ОписаниеОшибки.textRange.endLine 
		+ ОписаниеОшибки.textRange.startOffset + ОписаниеОшибки.textRange.endOffset, 
		"");
	КонецЕсли;
	
КонецФункции

Функция ВыполнитьЗапрос(Знач АдресСервера, Токен, URL, Операция) 
	
	Префикс = "/";
	Если СтрНайти(АдресСервера, "/") > 2 Тогда
		ЭлементыАдреса = СтрРазделить(АдресСервера, "/", Истина);
		АдресСервера = ЭлементыАдреса[0] + "/" + ЭлементыАдреса[1] + "/" + ЭлементыАдреса[2];
		Для Ит = 3 По ЭлементыАдреса.Количество() - 1 Цикл
			Если НЕ ЗначениеЗаполнено(ЭлементыАдреса[Ит]) Тогда
				Продолжить;
			КонецЕсли;
			
			Префикс = Префикс + ЭлементыАдреса[Ит] + "/";
		КонецЦикла;
	КонецЕсли;
	
	HTTPЗапрос = Новый HTTPЗапрос;
	HTTPЗапрос.АдресРесурса = Префикс + "api/" + URL;
	Сообщить(HTTPЗапрос.АдресРесурса);
	HTTPЗапрос.Заголовки.Вставить("Content-Type", "application/json");
	
	HTTP = Новый HTTPСоединение(АдресСервера, , Токен);
	Если Операция = "GET" Тогда
		ОтветHTTP = HTTP.Получить(HTTPЗапрос);
	Иначе 
		ОтветHTTP = HTTP.ОтправитьДляОбработки(HTTPЗапрос);
	КонецЕсли;
	
	Если ОтветHTTP.КодСостояния = 200 Тогда
		json = Новый ЧтениеJSON();
		json.УстановитьСтроку(ОтветHTTP.ПолучитьТелоКакСтроку());
		Возврат ПрочитатьJson(json);
	КонецЕсли;
	
	ТекстИсключения = СтрШаблон("Код ответа: %1
	|Ответ: %2
	|URL: %3",
	ОтветHTTP.КодСостояния, ОтветHTTP.ПолучитьТелоКакСтроку(), URL);
	ВызватьИсключение ТекстИсключения;
	
КонецФункции

///////////////////////////////////////////////////////////////////

Функция ПолучитьКоличествоЗамечанийКомпонента(АдресСервера, Токен, КлючКомпонента, СтатусыСтрокой = "")
	
	URL = "issues/search?ps=1&componentKeys=" + КлючКомпонента;
	Если Не ПустаяСтрока(СтатусыСтрокой) Тогда
		URL = URL + "&statuses=" + СтатусыСтрокой;
	КонецЕсли;
	ОтветСервера = ВыполнитьЗапрос(АдресСервера, Токен, URL, "GET");
	
	Возврат ОтветСервера.total;
	
КонецФункции	

Функция ПолучитьКлючиКомпонентов(АдресСервера, Токен, КлючКомпонента, СтатусыСтрокой, ТолькоКаталоги = Истина)
	
	КлючиКомпонент = Новый СписокЗначений();
	КоличествоЗамечанийПроекта = ПолучитьКоличествоЗамечанийКомпонента(АдресСервера, Токен, КлючКомпонента, СтатусыСтрокой);
	Если КоличествоЗамечанийПроекта > МаксимальныйРазмерПорцииДанных Тогда 
		
		URLШаблон = СтрШаблон("components/tree?component=%1%2&ps=500&p=", КлючКомпонента, ?(ТолькоКаталоги, "&qualifiers=DIR", ""));	
		НомерСтраницы = 1;
		Пока Истина Цикл
			URL = URLШаблон + Формат(НомерСтраницы, "ЧГ=");
			Ответ = ВыполнитьЗапрос(АдресСервера, Токен, URL, "GET");
			
			Для Каждого ОписаниеКомпонента Из Ответ.components Цикл
				КлючиКомпонент.Добавить(ОписаниеКомпонента.key);
			КонецЦикла;
			
			Если БольшеНетДанных(Ответ) Тогда
				Прервать;
			КонецЕсли;
			
			НомерСтраницы = НомерСтраницы + 1;
			
		КонецЦикла; 
		
	Иначе
		
		КлючиКомпонент.Добавить(КлючКомпонента);
		
	КонецЕсли;
	КлючиКомпонент.СортироватьПоЗначению();
	Возврат КлючиКомпонент.ВыгрузитьЗначения();
	
КонецФункции

///////////////////////////////////////////////////////////////////

МаксимальныйРазмерПорцииДанных = 10000;
