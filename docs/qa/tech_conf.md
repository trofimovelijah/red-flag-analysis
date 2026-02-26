# Особенности конфигурирования Платформы

## Проектирование базы ключ-значение

`Redis` выполняет следующие ключевые возможности:

| Возможности Redis | Описание | Требования |
|---|---|---|
|Управление состоянием сессий пользователя| - хранение текущего шага пользователя в Telegram-боте через FSM,<br> - отслеживание этапов загрузки документа и выполнения Анализа | - [ФТ-01](https://github.com/trofimovelijah/red-flag-analysis/issues/21),<br> - [ФТ-02](https://github.com/trofimovelijah/red-flag-analysis/issues/23),<br> - [ФТ-06](https://github.com/trofimovelijah/red-flag-analysis/issues/27),<br> - [ФТ-12](https://github.com/trofimovelijah/red-flag-analysis/issues/33),<br> - [ФТ-13](https://github.com/trofimovelijah/red-flag-analysis/issues/34),<br> - [ФТ-15](https://github.com/trofimovelijah/red-flag-analysis/issues/36),<br> - [ФТ-18](https://github.com/trofimovelijah/red-flag-analysis/issues/39),<br> - [ФТ-19](https://github.com/trofimovelijah/red-flag-analysis/issues/40),<br> - [ФТ-20](https://github.com/trofimovelijah/red-flag-analysis/issues/41) |
|Счётчик попыток на бесплатном тарифе| отслеживание количества использованных анализов (x/3) с TTL на сутки | - [ФТ-03](https://github.com/trofimovelijah/red-flag-analysis/issues/24),<br> - [ФТ-20](https://github.com/trofimovelijah/red-flag-analysis/issues/41),<br> - [ФТ-25](https://github.com/trofimovelijah/red-flag-analysis/issues/46) |
|Кэширование промежуточных данных| временное хранение метаданных загружаемых файлов, статусов обработки и результатов для быстрого доступа `n8n`-нодами | - [ФТ-07](https://github.com/trofimovelijah/red-flag-analysis/issues/28),<br> - [ФТ-08](https://github.com/trofimovelijah/red-flag-analysis/issues/29),<br> - [ФТ-11](https://github.com/trofimovelijah/red-flag-analysis/issues/32),<br> - [ФТ-14](https://github.com/trofimovelijah/red-flag-analysis/issues/35),<br> - [ФТ-24](https://github.com/trofimovelijah/red-flag-analysis/issues/45) |

## Проектирование файлового хранилища

`MinIO` выполняет функцию `S3`-совместимого объектного хранилища для временного размещения загруженных пользователем документов. Ключевое требование - транзитная обработка данных [ФТ-24](https://github.com/trofimovelijah/red-flag-analysis/issues/45) / [Без-1](https://github.com/trofimovelijah/red-flag-analysis/issues/61): документы должны обрабатываться и удаляться после завершения анализа. Основные возможности `MinIO`:

- буфер между загрузкой и обработкой - тг-бот принимает файл, сохраняет его в S3, в дальнейшем пайплайн (n8n-пайплайн) подхватывает его асинхронно,
- изоляция файлов по сессиям - каждый файл привязан к `session_id`, что исключает пересечения данных между пользователями,
- автоматическое удаление в соответствии с [ФТ-24](https://github.com/trofimovelijah/red-flag-analysis/issues/45) по TTL,
- единый интерфейс S3 API - n8n имеет встроенную ноду