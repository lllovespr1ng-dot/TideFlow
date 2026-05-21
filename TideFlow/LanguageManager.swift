import SwiftUI
import Combine

// MARK: - Language enum

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"
    case spanish = "es"
    case french  = "fr"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        case .spanish: return "Español"
        case .french:  return "Français"
        }
    }
}

// MARK: - String keys

enum LKey: String {
    // Greetings
    case greeting_night, greeting_morning, greeting_afternoon, greeting_evening
    // NowView
    case right_now, all_clear, no_more_events
    case next_label, after_that, leave_by
    case happening_now, very_soon, coming_up, until_start
    case allow_access, calendar_allow_btn, calendar_denied_desc
    // TodayView
    case today_title, nothing_scheduled, enjoy_open_water
    // PlanView
    case this_week, open_day
    // BrainDump
    case brain_dump, capture_everything, whats_on_mind
    case clear_done, done_section, focus_button
    // Presets
    case preset_yoga, preset_workout, preset_reading
    case preset_instagram, preset_work, preset_games
    // Focus mode
    case focusing_on, flowing, paused_label
    case im_done, wave_complete, back_to_dump
    // QuickAdd
    case quick_add, event_name, whats_happening
    case date_label, start_time, duration_label
    case add_to_calendar, cancel_label, custom_label, all_day_label
    // Settings
    case settings_title, language_label, save_label, creator_label
    // Tabs
    case tab_now, tab_today, tab_plan, tab_focus
    // Time abbreviations
    case hour_abbr, min_abbr
    // Onboarding
    case remember_choice
    // Plan — week navigation
    case select_week, delete_event
    // Notifications
    case notif_one_hour, notif_now, notif_focus_done
    // Brain dump
    case clear_all
}

// MARK: - Manager

class LanguageManager: ObservableObject {

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        language = AppLanguage(rawValue: saved) ?? .english
    }

    /// Returns the translated string for the current language.
    func t(_ key: LKey) -> String {
        LanguageManager.table[language]?[key]
            ?? LanguageManager.table[.english]?[key]
            ?? key.rawValue
    }

    /// Locale matching the current language — used for DateFormatter.
    var locale: Locale { Locale(identifier: language.rawValue) }

    /// Dynamic week label for the Plan tab.
    /// days == 0  → "This Week"
    /// days >  0  → "In 3 days" / "Через 3 дня"
    /// days <  0  → "3 days ago" / "3 дня назад"
    func weekOffsetLabel(days: Int) -> String {
        guard days != 0 else { return t(.this_week) }
        let n = abs(days)
        switch language {
        case .english:
            let word = n == 1 ? "day" : "days"
            return days > 0 ? "In \(n) \(word)" : "\(n) \(word) ago"
        case .russian:
            let word = russianDayForm(n)
            return days > 0 ? "Через \(n) \(word)" : "\(n) \(word) назад"
        case .spanish:
            let word = n == 1 ? "día" : "días"
            return days > 0 ? "En \(n) \(word)" : "Hace \(n) \(word)"
        case .french:
            let word = n <= 1 ? "jour" : "jours"
            return days > 0 ? "Dans \(n) \(word)" : "Il y a \(n) \(word)"
        }
    }

    /// Russian grammatical form of "день / дня / дней" following standard plural rules.
    private func russianDayForm(_ n: Int) -> String {
        let mod100 = n % 100
        let mod10  = n % 10
        if mod100 >= 11 && mod100 <= 19 { return "дней" }   // 11–19: дней
        switch mod10 {
        case 1:       return "день"                           // 1, 21, 31…
        case 2, 3, 4: return "дня"                           // 2–4, 22–24…
        default:      return "дней"                          // 5–9, 0, 25–29…
        }
    }

    /// Formats a duration in minutes using the correct hour/minute abbreviations for the current language.
    func durationLabel(_ totalMinutes: Int) -> String {
        let h    = totalMinutes / 60
        let m    = totalMinutes % 60
        let hStr = t(.hour_abbr)
        let mStr = t(.min_abbr)
        if totalMinutes < 60 { return "\(totalMinutes)\(mStr)" }
        return m == 0 ? "\(h)\(hStr)" : "\(h)\(hStr) \(m)\(mStr)"
    }

    // MARK: - Translation table

    private static let table: [AppLanguage: [LKey: String]] = [

        .english: [
            .greeting_night: "Good night",
            .greeting_morning: "Good morning",
            .greeting_afternoon: "Good afternoon",
            .greeting_evening: "Good evening",
            .right_now: "Right Now",
            .all_clear: "All clear",
            .no_more_events: "No more events today",
            .next_label: "NEXT", .after_that: "AFTER THAT", .leave_by: "Leave by",
            .happening_now: "happening now", .very_soon: "very soon",
            .coming_up: "coming up", .until_start: "until start",
            .allow_access: "Connect your calendar",
            .calendar_allow_btn: "Allow Access",
            .calendar_denied_desc: "Open Settings → Privacy → Calendars → TideFlow",
            .today_title: "Today",
            .nothing_scheduled: "Nothing scheduled",
            .enjoy_open_water: "Enjoy the open water ✦",
            .this_week: "This Week", .open_day: "Open day",
            .brain_dump: "Brain Dump", .capture_everything: "Capture everything",
            .whats_on_mind: "What's on your mind?",
            .clear_done: "Clear done", .done_section: "DONE", .focus_button: "Focus",
            .preset_yoga: "Yoga", .preset_workout: "Workout", .preset_reading: "Reading",
            .preset_instagram: "Instagram", .preset_work: "Work", .preset_games: "Video Games",
            .focusing_on: "Focusing on", .flowing: "flowing", .paused_label: "paused",
            .im_done: "I'm done  ✓", .wave_complete: "Done!", .back_to_dump: "Back to Brain Dump",
            .quick_add: "Quick Add", .event_name: "Event name",
            .whats_happening: "What's happening?",
            .date_label: "Date", .start_time: "Start time", .duration_label: "Duration",
            .add_to_calendar: "Add to Calendar", .cancel_label: "Cancel",
            .custom_label: "Custom", .all_day_label: "All Day",
            .settings_title: "Settings", .language_label: "Language", .save_label: "Save",
            .creator_label: "Creator",
            .tab_now: "Now", .tab_today: "Today", .tab_plan: "Plan", .tab_focus: "Focus",
            .hour_abbr: "h", .min_abbr: "m",
            .remember_choice: "We'll remember your choice so you won't have to pick it again.",
            .select_week: "Select Week", .delete_event: "Delete Event",
            .notif_one_hour: "Starting in 1 hour",
            .notif_now: "Starting now",
            .notif_focus_done: "Focus session complete!",
            .clear_all: "Clear all",
        ],

        .russian: [
            // Greetings — proper forms for each time of day
            .greeting_night: "Доброй ночи",        // genitive, 0–4
            .greeting_morning: "Доброе утро",       // nominative, 5–11
            .greeting_afternoon: "Добрый день",     // nominative, 12–16
            .greeting_evening: "Добрый вечер",      // nominative, 17–23
            .right_now: "Прямо сейчас",
            .all_clear: "Всё свободно",
            .no_more_events: "Больше событий нет",
            .next_label: "СЛЕДУЮЩЕЕ",
            .after_that: "ЗАТЕМ",
            .leave_by: "Уйти к",                   // деп. «уйти» естественнее, чем «выйти»
            .happening_now: "происходит сейчас",
            .very_soon: "совсем скоро",
            .coming_up: "скоро",
            .until_start: "до начала",
            .allow_access: "Подключи календарь",
            .calendar_allow_btn: "Разрешить доступ",
            .calendar_denied_desc: "Настройки → Конфиденциальность → Календари → TideFlow",
            .today_title: "Сегодня",
            .nothing_scheduled: "Ничего не запланировано",
            .enjoy_open_water: "Наслаждайся свободным временем ✦",
            .this_week: "Эта неделя",
            .open_day: "Свободный день",
            .brain_dump: "Поток мыслей",
            .capture_everything: "Записывай всё",
            .whats_on_mind: "Что у тебя на уме?",
            .clear_done: "Очистить выполненное",
            .done_section: "ВЫПОЛНЕНО",
            .focus_button: "Фокус",
            .preset_yoga: "Йога",
            .preset_workout: "Тренировка",
            .preset_reading: "Чтение",
            .preset_instagram: "Инстаграм",
            .preset_work: "Работа",
            .preset_games: "Игры",
            .focusing_on: "Работаю над",           // «Фокус на» звучит механически
            .flowing: "в потоке",
            .paused_label: "пауза",
            .im_done: "Готово ✓",
            .wave_complete: "Отлично!",             // более живое, чем просто «Готово!»
            .back_to_dump: "К задачам",
            .quick_add: "Быстрое добавление",
            .event_name: "Название события",
            .whats_happening: "Что планируешь?",
            .date_label: "Дата",
            .start_time: "Время начала",
            .duration_label: "Продолжительность",  // «длительность» менее употребимо
            .add_to_calendar: "Добавить в календарь",
            .cancel_label: "Отмена",
            .custom_label: "Другое",               // «Своё» грамматически подвешено
            .all_day_label: "Весь день",
            .settings_title: "Настройки",
            .language_label: "Язык",
            .save_label: "Сохранить",
            .creator_label: "Создатель",
            .tab_now: "Сейчас",
            .tab_today: "Сегодня",
            .tab_plan: "План",
            .tab_focus: "Задачи",
            .hour_abbr: "ч",
            .min_abbr: "мин",
            .remember_choice: "Мы запомним твой выбор, чтобы не спрашивать снова.",
            .select_week: "Выбрать неделю",
            .delete_event: "Удалить событие",
            .notif_one_hour: "Начнётся через час",
            .notif_now: "Начинается сейчас",
            .notif_focus_done: "Фокус-сессия завершена!",
            .clear_all: "Очистить всё",
        ],

        .spanish: [
            .greeting_night: "Buenas noches",
            .greeting_morning: "Buenos días",
            .greeting_afternoon: "Buenas tardes",
            .greeting_evening: "Buenas noches",
            .right_now: "Ahora mismo", .all_clear: "Todo despejado",
            .no_more_events: "No hay más eventos hoy",
            .next_label: "SIGUIENTE", .after_that: "DESPUÉS", .leave_by: "Salir a las",
            .happening_now: "en curso", .very_soon: "muy pronto",
            .coming_up: "próximamente", .until_start: "hasta el inicio",
            .allow_access: "Conecta tu calendario",
            .calendar_allow_btn: "Permitir acceso",
            .calendar_denied_desc: "Ajustes → Privacidad → Calendarios → TideFlow",
            .today_title: "Hoy", .nothing_scheduled: "Nada programado",
            .enjoy_open_water: "Disfruta el tiempo libre ✦",
            .this_week: "Esta semana", .open_day: "Día libre",
            .brain_dump: "Descarga mental", .capture_everything: "Captura todo",
            .whats_on_mind: "¿Qué tienes en mente?",
            .clear_done: "Limpiar", .done_section: "HECHO", .focus_button: "Enfoque",
            .preset_yoga: "Yoga", .preset_workout: "Ejercicio", .preset_reading: "Lectura",
            .preset_instagram: "Instagram", .preset_work: "Trabajo", .preset_games: "Videojuegos",
            .focusing_on: "Enfocado en", .flowing: "en flujo", .paused_label: "pausado",
            .im_done: "Listo ✓", .wave_complete: "¡Listo!", .back_to_dump: "Volver",
            .quick_add: "Agregar rápido", .event_name: "Nombre del evento",
            .whats_happening: "¿Qué está pasando?",
            .date_label: "Fecha", .start_time: "Hora de inicio", .duration_label: "Duración",
            .add_to_calendar: "Agregar al calendario", .cancel_label: "Cancelar",
            .custom_label: "Personalizado", .all_day_label: "Todo el día",
            .settings_title: "Ajustes", .language_label: "Idioma", .save_label: "Guardar",
            .creator_label: "Creador",
            .tab_now: "Ahora", .tab_today: "Hoy", .tab_plan: "Plan", .tab_focus: "Enfoque",
            .hour_abbr: "h", .min_abbr: "min",
            .remember_choice: "Recordaremos tu elección para que no tengas que elegir de nuevo.",
            .select_week: "Seleccionar semana", .delete_event: "Eliminar evento",
            .notif_one_hour: "Comienza en 1 hora",
            .notif_now: "Comienza ahora",
            .notif_focus_done: "¡Sesión de enfoque completada!",
            .clear_all: "Borrar todo",
        ],

        .french: [
            .greeting_night: "Bonne nuit",
            .greeting_morning: "Bonjour",
            .greeting_afternoon: "Bon après-midi",
            .greeting_evening: "Bonsoir",
            .right_now: "En ce moment", .all_clear: "Tout est libre",
            .no_more_events: "Plus d'événements aujourd'hui",
            .next_label: "SUIVANT", .after_that: "ENSUITE", .leave_by: "Partir à",
            .happening_now: "en cours", .very_soon: "très bientôt",
            .coming_up: "bientôt", .until_start: "avant le début",
            .allow_access: "Connecte ton calendrier",
            .calendar_allow_btn: "Autoriser l'accès",
            .calendar_denied_desc: "Réglages → Confidentialité → Calendriers → TideFlow",
            .today_title: "Aujourd'hui", .nothing_scheduled: "Rien de prévu",
            .enjoy_open_water: "Profite du temps libre ✦",
            .this_week: "Cette semaine", .open_day: "Journée libre",
            .brain_dump: "Vider la tête", .capture_everything: "Tout noter",
            .whats_on_mind: "À quoi tu penses ?",
            .clear_done: "Effacer", .done_section: "FAIT", .focus_button: "Focus",
            .preset_yoga: "Yoga", .preset_workout: "Entraînement", .preset_reading: "Lecture",
            .preset_instagram: "Instagram", .preset_work: "Travail", .preset_games: "Jeux vidéo",
            .focusing_on: "Je travaille sur", .flowing: "en cours", .paused_label: "en pause",
            .im_done: "Terminé ✓", .wave_complete: "Terminé !", .back_to_dump: "Retour",
            .quick_add: "Ajout rapide", .event_name: "Nom de l'événement",
            .whats_happening: "Qu'est-ce qui se passe ?",
            .date_label: "Date", .start_time: "Heure de début", .duration_label: "Durée",
            .add_to_calendar: "Ajouter au calendrier", .cancel_label: "Annuler",
            .custom_label: "Personnalisé", .all_day_label: "Toute la journée",
            .settings_title: "Paramètres", .language_label: "Langue", .save_label: "Enregistrer",
            .creator_label: "Créateur",
            .tab_now: "Maintenant", .tab_today: "Aujourd'hui",
            .tab_plan: "Plan", .tab_focus: "Focus",
            .hour_abbr: "h", .min_abbr: "min",
            .remember_choice: "Nous mémoriserons ton choix pour que tu n'aies pas à le refaire.",
            .select_week: "Choisir la semaine", .delete_event: "Supprimer l'événement",
            .notif_one_hour: "Commence dans 1 heure",
            .notif_now: "Commence maintenant",
            .notif_focus_done: "Session de focus terminée !",
            .clear_all: "Tout effacer",
        ],
    ]
}
