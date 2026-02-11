-- Файл для быстрой правки текста таймеров и анонсов
QDKP2_ICCTimers = {
    WithQuest = {
        "/dbm pull 65",
        "/dbm broadcast timer 4865 300DKP",
        "/dbm broadcast timer 5465 150DKP",
        "/rw Делаем квесты. Если убиваем за 1ч20мин - лутаем 300DKP, за 1ч30мин - лутаем 150DKP",
    },
    
    NoQuest = {
        "/dbm pull 65",
        "/dbm broadcast timer 4265 300DKP",
        "/dbm broadcast timer 4865 150DKP",
        "/rw Если убиваем за 1ч10мин - лутаем 300DKP, за 1ч20мин - лутаем 150DKP",
    }
}