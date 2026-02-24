-- ====================================================
-- ЗАДАНИЕ 3: Время между первой и второй сессией
-- ====================================================

-- КОНТЕКСТ ЗАДАЧИ:
-- Сколько времени проходит между первой и второй сессией у менторов?
-- А у менти?
-- ====================================================

-- ====================================================
-- ЧАСТЬ 1. Менторы
-- ====================================================
-- Рассчитываем два показателя:
-- - Среднее (avg) — общая картина
-- - Медиана (median) — значение, устойчивое к выбросам
-- Сравнение этих метрик показывает, есть ли "хвост" из пользователей с очень долгим возвратом.
-- ====================================================

WITH mentor_sessions AS (
	-- Все успешные сессии менторов с порядковым номером по времени
    SELECT
        mentor_id,
        session_date_time,
        ROW_NUMBER() OVER (
            PARTITION BY mentor_id 
            ORDER BY session_date_time
        ) AS session_rank
    FROM sessions
    WHERE session_status = 'finished'
),
first_two_mentor AS (
	-- Первая и вторая сессия для каждого ментора (если есть)
    SELECT
        mentor_id,
        MAX(CASE WHEN session_rank = 1 THEN session_date_time END) AS first_session,
        MAX(CASE WHEN session_rank = 2 THEN session_date_time END) AS second_session
    FROM mentor_sessions
    WHERE session_rank <= 2
    GROUP BY mentor_id
    HAVING COUNT(*) = 2
),
days_between AS (
	-- Разница в днях между первой и второй сессией
    SELECT
        EXTRACT(DAY FROM (second_session - first_session)) AS days
    FROM first_two_mentor
)
SELECT
    'mentor' AS role,
    ROUND(AVG(days)::numeric, 1) AS avg_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days)::numeric, 1) AS median_days
FROM days_between;

-- ====================================================
-- РЕЗУЛЬТАТ ЧАСТИ 1:
-- ====================================================
-- 
-- | role   | avg_days | median_days |
-- |--------|---------:|------------:|
-- | mentor | 52.2     | 28.0        |
--
-- ====================================================

-- ====================================================
-- ЧАСТЬ 2. Менти
-- ====================================================

WITH mentee_sessions AS (
	-- Все успешные сессии менти с порядковым номером по времени
    SELECT
        mentee_id,
        session_date_time,
        ROW_NUMBER() OVER (
            PARTITION BY mentee_id 
            ORDER BY session_date_time
        ) AS session_rank
    FROM sessions
    WHERE session_status = 'finished'
),
first_two_mentee AS (
	-- Первая и вторая сессия для каждого менти (если есть)
    SELECT
        mentee_id,
        MAX(CASE WHEN session_rank = 1 THEN session_date_time END) AS first_session,
        MAX(CASE WHEN session_rank = 2 THEN session_date_time END) AS second_session
    FROM mentee_sessions
    WHERE session_rank <= 2
    GROUP BY mentee_id
    HAVING COUNT(*) = 2
),
days_between AS (
	-- Разница в днях между первой и второй сессией
    SELECT
        EXTRACT(DAY FROM (second_session - first_session)) AS days
    FROM first_two_mentee
)
SELECT
    'mentee' AS role,
    ROUND(AVG(days)::numeric, 1) AS avg_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days)::numeric, 1) AS median_days
FROM days_between;

-- ====================================================
-- РЕЗУЛЬТАТ ЧАСТИ 2:
-- ====================================================
-- 
-- | role   | avg_days | median_days |
-- |--------|---------:|------------:|
-- | mentee | 78.1     | 47.0        |
--
-- ====================================================

-- ====================================================
-- ВЫВОДЫ:
-- ====================================================

-- 1. Типичный срок возврата (медиана):
--    - Менторы возвращаются через 28 дней
--    - Менти возвращаются через 47 дней
--
-- 2. Значительный разрыв между средним и медианой
--    (менторы: 52.2 vs 28, менти: 78.1 vs 47) говорит о наличии
--    "хвоста" — части пользователей, которые возвращаются
--    через очень долгое время (более 100 дней).
--
-- 3. Это означает, что:
--    - Большинство пользователей возвращается быстрее, чем казалось по среднему
--    - Но есть сегмент "спящих", которых можно попробовать реактивировать
--
-- 4. Разница между ролями сохраняется на всех метриках:
--    Менторы стабильно возвращаются в 1.5-1.7 раза быстрее менти.
--
-- 5. Рекомендации:
--    - Фокус на удержание в первый месяц
--    - Для "хвоста" (100+ дней) — отдельная кампания по возврату
--    - Менти требуют больше внимания — они возвращаются почти в 2 раза дольше
-- ====================================================