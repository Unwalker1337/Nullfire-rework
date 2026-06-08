# NullFire Hub

Репозиторий скриптов для Roblox исполнителей. Поддерживает sub-places.

## Структура

```
Nullfire-rework/
├── loader.lua          — Главный загрузчик (вставь в executor)
├── places.json         — Конфиг: привязка скриптов к place ID
├── scripts/            — Папка со скриптами
│   └── SoundSpy.lua    — Отладка звуков
└── places/             — Скрипты под конкретные места
```

## Использование

1. Вставь `loader.lua` в executor
2. Загрузчик сам определит place ID и загрузит нужные скрипты
3. Или добавь новые place ID в `places.json`

## Где брать Place ID

`game.PlaceId` в игре.

## Добавление нового места

В `places.json`:

```json
"123456789": {
  "name": "Название игры",
  "scripts": ["SoundSpy"]
}
```
