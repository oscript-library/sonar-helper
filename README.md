# Sonar Helper

Предоставляет набор утилит, помогающих при работе с SonarQube.

При работе используется REST API SonarQube.

Обращаю внимание, что для выполнения большинства операций необходимы расширенные права пользователя.

## Возможности

На данный момент предоставляются следующие инструменты:

### Закрытие замечаний, привнесенных родительским проектом

Часто возникают ситуации, когда в разных проектах используется общая кодовая база и есть потребность исключить замечания родительского проекта, т.к. исправление их в дочернем самостоятельно не планируется. Переносить руками все замечания достаточно проблематично.

Для закрытия замечаний необходимо вызвать команду **`issue-resolver`** и передать ей информацию для авторизации, данные родительского и дочерних проектов.

#### Логика закрытия замечаний

SonarQube может создавать несколько замечаний по одному правилу на одну строку, на один символ / подстроку, что приводит к формированию одноко хэша строки. Примером таких замечаний например являются правила наличия пробелов у знаков математических операций и отсутствие описаний параметров методов.

Для гарантии корректрого закрытия замечаний дочернего проекта ввене алгоритм, при котором закрытие в довернем проекте замечний возможно только при выполнении следующих условий:

- количество одинаковых замечаний (с одинаковым хэшем и правилом) должно совпадать с родительским
- количество одинаковых незакрытых замечаний в дочернем проекте должны быть большим или равным количеству закрываемых замечаний из родительского проекта

В дочернем проекте будет закрыто то количество замечаний, которое неоьбходимо для выравнивая по количеству с родительским.

**Примеры:**

**Пример 1:** В родительском проекте есть 3 замечания на строке, исправлено одно. В дочернем тоже 3 замечания, исправленных нет. В результате - бцдет закрыто одно замечание в дочернем проекте.

**Пример 2:** В родительском проекте есть 3 замечания на строке, исправлено одно. В дочернем тоже 3 замечания, исправленных 2. В результате - в дочернем проекте не будет закрыто ни одного нового замечания.

**Пример 3:** В родительском проекте есть 3 замечания на строке, исправлено два. В дочернем тоже 3 замечания, исправленных 1. В результате - в дочернем проекте будет закрыто еще одно замечание, и общее количество закрых станет 2.

**Пример 4:** В родительском проекте есть 3 замечания на строке, исправлено два. В дочернем 4 замечания, исправленных 1. В результате - в дочернем проекте не будет закрыто ни одного нового замечния.

### Отчет по проектам

При необходимоси получить отчет по проектам (по интересующим метрикам) и использовать его в других приложениях (либо рассылать по почте) можно вручную собирать информацию по страницам SonarQube, но проще использовать **`sonar-helper`**, вызвав команду **`report`** и передав ей информации для авторизации, список проектов и интересующих метрик.

На данный момент поддерживаются следующие варианты формирования отчета:

- **JSON** - формируется отчет в формате json, метрики выгружаются дважды - для идентификатора метрики и для русского представления. [Пример: examples\example-report.json](examples\example-report.json)
- **HTML** - формируется отчет в формате html, метрики выгнржаются только для русского представления. [Пример: examples\example-report.html](examples\example-report.html)

## Примеры

Примеры отчетов и конфигурационных файлов находятся в каталоге [examples](examples)
