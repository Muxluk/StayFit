-- =============================================================================
-- БАЗА ДАНИХ STAYFIT (PostgreSQL)
-- Повна схема з усіма таблицями, зв'язками та каскадними видаленнями
-- =============================================================================

-- Створення бази даних
CREATE DATABASE stayfit_db
    WITH 
    ENCODING = 'UTF8'
    LC_COLLATE = 'uk_UA.UTF-8'
    LC_CTYPE = 'uk_UA.UTF-8'
    TEMPLATE = template0;


-- Створення необхідних розширень
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- СТВОРЕННЯ ENUM ТИПІВ
-- =============================================================================

CREATE TYPE gender_type AS ENUM ('MALE', 'FEMALE');
CREATE TYPE activity_level_type AS ENUM ('MINIMAL', 'LOW', 'MODERATE', 'HIGH', 'VERY_HIGH');
CREATE TYPE user_role_type AS ENUM ('USER', 'ADMIN', 'GUEST');
CREATE TYPE goal_type AS ENUM ('WEIGHT_LOSS', 'WEIGHT_GAIN', 'MAINTENANCE');
CREATE TYPE product_category_type AS ENUM ('FRUITS', 'VEGETABLES', 'MEAT', 'DAIRY', 'GRAINS', 'BEVERAGES', 'SWEETS', 'FASTFOOD', 'OTHER');
CREATE TYPE measurement_system_type AS ENUM ('METRIC', 'IMPERIAL');
CREATE TYPE theme_type AS ENUM ('LIGHT', 'DARK', 'AUTO');
CREATE TYPE log_status_type AS ENUM ('SUCCESS', 'FAILURE', 'WARNING');

-- =============================================================================
-- ТАБЛИЦЯ 1: USERS (Користувачі)
-- =============================================================================
CREATE TABLE users (
    user_id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    age INTEGER NOT NULL CHECK (age >= 12 AND age <= 100),
    gender gender_type NOT NULL,
    height NUMERIC(5,2) NOT NULL CHECK (height >= 100 AND height <= 250),
    current_weight NUMERIC(5,2) NOT NULL CHECK (current_weight >= 30 AND current_weight <= 300),
    target_weight NUMERIC(5,2) NOT NULL CHECK (target_weight >= 30 AND target_weight <= 300),
    activity_level activity_level_type NOT NULL,
    bmr NUMERIC(7,2) NOT NULL,
    tdee NUMERIC(7,2) NOT NULL,
    bmi NUMERIC(4,2) NOT NULL,
    bmi_category VARCHAR(50) NOT NULL,
    role user_role_type NOT NULL DEFAULT 'USER',
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    profile_photo_url VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Індекси для Users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_users_created_at ON users(created_at);

-- =============================================================================
-- ТАБЛИЦЯ 2: USER_SETTINGS (Налаштування користувача)
-- Каскадне видалення: при видаленні користувача видаляються його налаштування
-- =============================================================================
CREATE TABLE user_settings (
    settings_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    measurement_system measurement_system_type NOT NULL DEFAULT 'METRIC',
    language VARCHAR(10) NOT NULL DEFAULT 'uk',
    theme theme_type NOT NULL DEFAULT 'LIGHT',
    reminder_food_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    reminder_water_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    weekly_reports_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    reminder_time TIME,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_settings_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(user_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- Індекси для UserSettings
CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);

-- =============================================================================
-- ТАБЛИЦЯ 3: USER_GOALS (Цілі харчування користувача)
-- Каскадне видалення: при видаленні користувача видаляються його цілі
-- =============================================================================
CREATE TABLE user_goals (
    goal_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    daily_calories NUMERIC(7,2) NOT NULL CHECK (daily_calories > 0),
    is_auto_calculated BOOLEAN NOT NULL DEFAULT TRUE,
    goal_type goal_type NOT NULL,
    protein_grams NUMERIC(6,2) NOT NULL CHECK (protein_grams >= 0),
    fat_grams NUMERIC(6,2) NOT NULL CHECK (fat_grams >= 0),
    carbs_grams NUMERIC(6,2) NOT NULL CHECK (carbs_grams >= 0),
    protein_percent NUMERIC(5,2) NOT NULL CHECK (protein_percent >= 0 AND protein_percent <= 100),
    fat_percent NUMERIC(5,2) NOT NULL CHECK (fat_percent >= 0 AND fat_percent <= 100),
    carbs_percent NUMERIC(5,2) NOT NULL CHECK (carbs_percent >= 0 AND carbs_percent <= 100),
    meals_per_day INTEGER NOT NULL CHECK (meals_per_day >= 3 AND meals_per_day <= 6),
    weight_change_rate NUMERIC(4,2) CHECK (weight_change_rate >= 0.25 AND weight_change_rate <= 1),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_goals_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(user_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- Індекси для UserGoals
CREATE INDEX idx_user_goals_user_id ON user_goals(user_id);
CREATE INDEX idx_user_goals_user_active ON user_goals(user_id, is_active);

-- =============================================================================
-- ТАБЛИЦЯ 4: PRODUCTS (База продуктів)
-- При видаленні користувача: created_by_user_id = NULL (SET NULL)
-- =============================================================================
CREATE TABLE products (
    product_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category product_category_type NOT NULL,
    calories_per_100g NUMERIC(6,2) NOT NULL CHECK (calories_per_100g >= 0),
    protein_per_100g NUMERIC(5,2) NOT NULL CHECK (protein_per_100g >= 0),
    fat_per_100g NUMERIC(5,2) NOT NULL CHECK (fat_per_100g >= 0),
    carbs_per_100g NUMERIC(5,2) NOT NULL CHECK (carbs_per_100g >= 0),
    is_global BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_user_id BIGINT,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_products_user 
        FOREIGN KEY (created_by_user_id) 
        REFERENCES users(user_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE
);

-- Індекси для Products
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_is_global ON products(is_global);
CREATE INDEX idx_products_created_by_user ON products(created_by_user_id);

-- =============================================================================
-- ТАБЛИЦЯ 5: MEAL_TYPES (Типи прийомів їжі)
-- =============================================================================
CREATE TABLE meal_types (
    meal_type_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    display_order INTEGER NOT NULL,
    default_time_start TIME,
    default_time_end TIME
);

-- Індекси для MealTypes
CREATE INDEX idx_meal_types_display_order ON meal_types(display_order);

-- Вставка типів прийомів їжі за замовчуванням
INSERT INTO meal_types (name, display_order, default_time_start, default_time_end) VALUES
('BREAKFAST', 1, '07:00:00', '10:00:00'),
('LUNCH', 2, '12:00:00', '15:00:00'),
('DINNER', 3, '18:00:00', '21:00:00'),
('SNACK', 4, NULL, NULL);

-- =============================================================================
-- ТАБЛИЦЯ 6: FOOD_DIARY (Щоденник харчування)
-- Каскадне видалення: при видаленні користувача видаляються його записи
-- RESTRICT: не можна видалити продукт, якщо є записи
-- =============================================================================
CREATE TABLE food_diary (
    diary_entry_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    meal_type_id INTEGER NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    weight_grams NUMERIC(7,2) NOT NULL CHECK (weight_grams > 0),
    calories NUMERIC(7,2) NOT NULL CHECK (calories >= 0),
    protein NUMERIC(6,2) NOT NULL CHECK (protein >= 0),
    fat NUMERIC(6,2) NOT NULL CHECK (fat >= 0),
    carbs NUMERIC(6,2) NOT NULL CHECK (carbs >= 0),
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_food_diary_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(user_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_food_diary_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(product_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT fk_food_diary_meal_type 
        FOREIGN KEY (meal_type_id) 
        REFERENCES meal_types(meal_type_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
);

-- Індекси для FoodDiary
CREATE INDEX idx_food_diary_user_date ON food_diary(user_id, date);
CREATE INDEX idx_food_diary_date ON food_diary(date);
CREATE INDEX idx_food_diary_meal_type ON food_diary(meal_type_id);
CREATE INDEX idx_food_diary_product ON food_diary(product_id);

-- =============================================================================
-- ТАБЛИЦЯ 7: WEIGHT_HISTORY (Історія ваги)
-- Каскадне видалення: при видаленні користувача видаляється його історія ваги
-- =============================================================================
CREATE TABLE weight_history (
    weight_entry_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    date DATE NOT NULL,
    weight NUMERIC(5,2) NOT NULL CHECK (weight >= 30 AND weight <= 300),
    bmi NUMERIC(4,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_weight_history_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(user_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT uq_weight_history_user_date 
        UNIQUE (user_id, date)
);

-- Індекси для WeightHistory
CREATE INDEX idx_weight_history_user_date ON weight_history(user_id, date DESC);

-- =============================================================================
-- ТАБЛИЦЯ 8: USER_SESSIONS (Сесії користувачів)
-- Каскадне видалення: при видаленні користувача видаляються його сесії
-- =============================================================================
CREATE TABLE user_sessions (
    session_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    access_token_hash VARCHAR(255) NOT NULL UNIQUE,
    refresh_token_hash VARCHAR(255) NOT NULL UNIQUE,
    device_info VARCHAR(500),
    ip_address VARCHAR(45),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    access_token_expires_at TIMESTAMP NOT NULL,
    refresh_token_expires_at TIMESTAMP NOT NULL,
    last_activity TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_sessions_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(user_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- Індекси для UserSessions
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_user_active ON user_sessions(user_id, is_active);
CREATE INDEX idx_user_sessions_access_token ON user_sessions(access_token_hash);
CREATE INDEX idx_user_sessions_refresh_token ON user_sessions(refresh_token_hash);

-- =============================================================================
-- ТАБЛИЦЯ 9: PASSWORD_RESET_TOKENS (Токени відновлення паролю)
-- Каскадне видалення: при видаленні користувача видаляються його токени
-- =============================================================================
CREATE TABLE password_reset_tokens (
    token_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    token_code VARCHAR(6) NOT NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_password_reset_tokens_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(user_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- Індекси для PasswordResetTokens
CREATE INDEX idx_password_reset_tokens_user_id ON password_reset_tokens(user_id);
CREATE INDEX idx_password_reset_tokens_token_code ON password_reset_tokens(token_code, is_used);

-- =============================================================================
-- ТАБЛИЦЯ 10: ACTIVITY_LOG (Логи активності)
-- SET NULL: при видаленні користувача зберігаємо історію, але user_id = NULL
-- =============================================================================
CREATE TABLE activity_log (
    log_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    action_type VARCHAR(100) NOT NULL,
    description TEXT,
    ip_address VARCHAR(45),
    status log_status_type NOT NULL DEFAULT 'SUCCESS',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_activity_log_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(user_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE
);

-- Індекси для ActivityLog
CREATE INDEX idx_activity_log_user_id ON activity_log(user_id);
CREATE INDEX idx_activity_log_action_type ON activity_log(action_type);
CREATE INDEX idx_activity_log_created_at ON activity_log(created_at DESC);
CREATE INDEX idx_activity_log_action_type_time ON activity_log(action_type, created_at DESC);

-- =============================================================================
-- ТАБЛИЦЯ 11: DAILY_SUMMARY (Щоденні підсумки)
-- Каскадне видалення: при видаленні користувача видаляються його підсумки
-- =============================================================================
CREATE TABLE daily_summary (
    summary_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    date DATE NOT NULL,
    total_calories NUMERIC(7,2) NOT NULL DEFAULT 0,
    total_protein NUMERIC(6,2) NOT NULL DEFAULT 0,
    total_fat NUMERIC(6,2) NOT NULL DEFAULT 0,
    total_carbs NUMERIC(6,2) NOT NULL DEFAULT 0,
    goal_achieved BOOLEAN NOT NULL DEFAULT FALSE,
    goal_percentage NUMERIC(5,2) NOT NULL DEFAULT 0,
    breakfast_calories NUMERIC(7,2) NOT NULL DEFAULT 0,
    lunch_calories NUMERIC(7,2) NOT NULL DEFAULT 0,
    dinner_calories NUMERIC(7,2) NOT NULL DEFAULT 0,
    snack_calories NUMERIC(7,2) NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_daily_summary_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(user_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT uq_daily_summary_user_date 
        UNIQUE (user_id, date)
);

-- Індекси для DailySummary
CREATE INDEX idx_daily_summary_date ON daily_summary(date);
CREATE INDEX idx_daily_summary_user_date ON daily_summary(user_id, date);

-- =============================================================================
-- ТАБЛИЦЯ 12: RECIPES (Рецепти)
-- Каскадне видалення: при видаленні користувача видаляються його рецепти
-- =============================================================================
CREATE TABLE recipes (
    recipe_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    servings INTEGER NOT NULL CHECK (servings > 0),
    total_calories NUMERIC(7,2) NOT NULL,
    total_protein NUMERIC(6,2) NOT NULL,
    total_fat NUMERIC(6,2) NOT NULL,
    total_carbs NUMERIC(6,2) NOT NULL,
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_recipes_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(user_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- Індекси для Recipes
CREATE INDEX idx_recipes_user_id ON recipes(user_id);
CREATE INDEX idx_recipes_is_public ON recipes(is_public);
CREATE INDEX idx_recipes_name ON recipes(name);

-- =============================================================================
-- ТАБЛИЦЯ 13: RECIPE_INGREDIENTS (Інгредієнти рецептів)
-- Каскадне видалення: при видаленні рецепту видаляються його інгредієнти
-- RESTRICT: не можна видалити продукт, якщо він використовується в рецепті
-- =============================================================================
CREATE TABLE recipe_ingredients (
    ingredient_id BIGSERIAL PRIMARY KEY,
    recipe_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    weight_grams NUMERIC(7,2) NOT NULL CHECK (weight_grams > 0),
    order_index INTEGER NOT NULL,
    CONSTRAINT fk_recipe_ingredients_recipe 
        FOREIGN KEY (recipe_id) 
        REFERENCES recipes(recipe_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_recipe_ingredients_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(product_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
);

-- Індекси для RecipeIngredients
CREATE INDEX idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);
CREATE INDEX idx_recipe_ingredients_product_id ON recipe_ingredients(product_id);

-- =============================================================================
-- ТРИГЕРИ ДЛЯ АВТОМАТИЧНОГО ОНОВЛЕННЯ updated_at
-- =============================================================================

-- Функція для оновлення updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Застосування тригерів до таблиць
CREATE TRIGGER trg_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_user_settings_updated_at 
    BEFORE UPDATE ON user_settings 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_user_goals_updated_at 
    BEFORE UPDATE ON user_goals 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_products_updated_at 
    BEFORE UPDATE ON products 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_food_diary_updated_at 
    BEFORE UPDATE ON food_diary 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_recipes_updated_at 
    BEFORE UPDATE ON recipes 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_daily_summary_updated_at 
    BEFORE UPDATE ON daily_summary 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- ТРИГЕРИ ДЛЯ АВТОМАТИЧНОГО ОНОВЛЕННЯ DAILY_SUMMARY
-- =============================================================================

-- Функція для оновлення daily_summary після додавання запису
CREATE OR REPLACE FUNCTION update_daily_summary_after_insert()
RETURNS TRIGGER AS $$
DECLARE
    v_meal_name VARCHAR(50);
BEGIN
    -- Отримуємо назву типу прийому їжі
    SELECT name INTO v_meal_name FROM meal_types WHERE meal_type_id = NEW.meal_type_id;
    
    -- Вставка або оновлення daily_summary
    INSERT INTO daily_summary (
        user_id, date, total_calories, total_protein, total_fat, total_carbs,
        breakfast_calories, lunch_calories, dinner_calories, snack_calories
    ) VALUES (
        NEW.user_id, NEW.date, NEW.calories, NEW.protein, NEW.fat, NEW.carbs,
        CASE WHEN v_meal_name = 'BREAKFAST' THEN NEW.calories ELSE 0 END,
        CASE WHEN v_meal_name = 'LUNCH' THEN NEW.calories ELSE 0 END,
        CASE WHEN v_meal_name = 'DINNER' THEN NEW.calories ELSE 0 END,
        CASE WHEN v_meal_name = 'SNACK' THEN NEW.calories ELSE 0 END
    )
    ON CONFLICT (user_id, date) 
    DO UPDATE SET
        total_calories = daily_summary.total_calories + NEW.calories,
        total_protein = daily_summary.total_protein + NEW.protein,
        total_fat = daily_summary.total_fat + NEW.fat,
        total_carbs = daily_summary.total_carbs + NEW.carbs,
        breakfast_calories = daily_summary.breakfast_calories + 
            CASE WHEN v_meal_name = 'BREAKFAST' THEN NEW.calories ELSE 0 END,
        lunch_calories = daily_summary.lunch_calories + 
            CASE WHEN v_meal_name = 'LUNCH' THEN NEW.calories ELSE 0 END,
        dinner_calories = daily_summary.dinner_calories + 
            CASE WHEN v_meal_name = 'DINNER' THEN NEW.calories ELSE 0 END,
        snack_calories = daily_summary.snack_calories + 
            CASE WHEN v_meal_name = 'SNACK' THEN NEW.calories ELSE 0 END,
        updated_at = CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Функція для оновлення daily_summary після оновлення запису
CREATE OR REPLACE FUNCTION update_daily_summary_after_update()
RETURNS TRIGGER AS $$
DECLARE
    v_old_meal_name VARCHAR(50);
    v_new_meal_name VARCHAR(50);
BEGIN
    -- Отримуємо назви типів прийомів їжі
    SELECT name INTO v_old_meal_name FROM meal_types WHERE meal_type_id = OLD.meal_type_id;
    SELECT name INTO v_new_meal_name FROM meal_types WHERE meal_type_id = NEW.meal_type_id;
    
    -- Віднімаємо старі значення
    UPDATE daily_summary SET
        total_calories = total_calories - OLD.calories,
        total_protein = total_protein - OLD.protein,
        total_fat = total_fat - OLD.fat,
        total_carbs = total_carbs - OLD.carbs,
        breakfast_calories = breakfast_calories - 
            CASE WHEN v_old_meal_name = 'BREAKFAST' THEN OLD.calories ELSE 0 END,
        lunch_calories = lunch_calories - 
            CASE WHEN v_old_meal_name = 'LUNCH' THEN OLD.calories ELSE 0 END,
        dinner_calories = dinner_calories - 
            CASE WHEN v_old_meal_name = 'DINNER' THEN OLD.calories ELSE 0 END,
        snack_calories = snack_calories - 
            CASE WHEN v_old_meal_name = 'SNACK' THEN OLD.calories ELSE 0 END,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = OLD.user_id AND date = OLD.date;
    
    -- Додаємо нові значення
    UPDATE daily_summary SET
        total_calories = total_calories + NEW.calories,
        total_protein = total_protein + NEW.protein,
        total_fat = total_fat + NEW.fat,
        total_carbs = total_carbs + NEW.carbs,
        breakfast_calories = breakfast_calories + 
            CASE WHEN v_new_meal_name = 'BREAKFAST' THEN NEW.calories ELSE 0 END,
        lunch_calories = lunch_calories + 
            CASE WHEN v_new_meal_name = 'LUNCH' THEN NEW.calories ELSE 0 END,
        dinner_calories = dinner_calories + 
            CASE WHEN v_new_meal_name = 'DINNER' THEN NEW.calories ELSE 0 END,
        snack_calories = snack_calories + 
            CASE WHEN v_new_meal_name = 'SNACK' THEN NEW.calories ELSE 0 END,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = NEW.user_id AND date = NEW.date;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Функція для оновлення daily_summary після видалення запису
CREATE OR REPLACE FUNCTION update_daily_summary_after_delete()
RETURNS TRIGGER AS $$
DECLARE
    v_meal_name VARCHAR(50);
BEGIN
    -- Отримуємо назву типу прийому їжі
    SELECT name INTO v_meal_name FROM meal_types WHERE meal_type_id = OLD.meal_type_id;
    
    -- Віднімаємо значення
    UPDATE daily_summary SET
        total_calories = total_calories - OLD.calories,
        total_protein = total_protein - OLD.protein,
        total_fat = total_fat - OLD.fat,
        total_carbs = total_carbs - OLD.carbs,
        breakfast_calories = breakfast_calories - 
            CASE WHEN v_meal_name = 'BREAKFAST' THEN OLD.calories ELSE 0 END,
        lunch_calories = lunch_calories - 
            CASE WHEN v_meal_name = 'LUNCH' THEN OLD.calories ELSE 0 END,
        dinner_calories = dinner_calories - 
            CASE WHEN v_meal_name = 'DINNER' THEN OLD.calories ELSE 0 END,
        snack_calories = snack_calories - 
            CASE WHEN v_meal_name = 'SNACK' THEN OLD.calories ELSE 0 END,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = OLD.user_id AND date = OLD.date;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Створення тригерів для food_diary
CREATE TRIGGER trg_food_diary_after_insert
    AFTER INSERT ON food_diary
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_summary_after_insert();

CREATE TRIGGER trg_food_diary_after_update
    AFTER UPDATE ON food_diary
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_summary_after_update();

CREATE TRIGGER trg_food_diary_after_delete
    AFTER DELETE ON food_diary
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_summary_after_delete();

-- =============================================================================
-- ПРЕДСТАВЛЕННЯ (VIEWS) ДЛЯ ЗРУЧНОЇ РОБОТИ З ДАНИМИ
-- =============================================================================

-- Представлення для активних цілей користувачів
CREATE OR REPLACE VIEW v_active_user_goals AS
SELECT 
    u.user_id,
    u.email,
    u.first_name,
    u.last_name,
    ug.goal_id,
    ug.daily_calories,
    ug.goal_type,
    ug.protein_grams,
    ug.fat_grams,
    ug.carbs_grams,
    ug.meals_per_day
FROM users u
INNER JOIN user_goals ug ON u.user_id = ug.user_id
WHERE ug.is_active = TRUE AND u.is_active = TRUE;

-- Представлення для щоденника харчування з деталями
CREATE OR REPLACE VIEW v_food_diary_detailed AS
SELECT 
    fd.diary_entry_id,
    fd.user_id,
    u.first_name,
    u.last_name,
    fd.date,
    fd.time,
    mt.name as meal_type,
    p.name as product_name,
    p.category,
    fd.weight_grams,
    fd.calories,
    fd.protein,
    fd.fat,
    fd.carbs,
    fd.notes
FROM food_diary fd
INNER JOIN users u ON fd.user_id = u.user_id
INNER JOIN products p ON fd.product_id = p.product_id
INNER JOIN meal_types mt ON fd.meal_type_id = mt.meal_type_id;

-- Представлення для прогресу користувачів
CREATE OR REPLACE VIEW v_user_progress AS
SELECT 
    u.user_id,
    u.email,
    u.first_name,
    u.last_name,
    u.current_weight,
    u.target_weight,
    u.height,
    u.bmi,
    u.bmi_category,
    wh.weight as latest_weight,
    wh.date as latest_weight_date,
    (u.current_weight - u.target_weight) as weight_to_goal
FROM users u
LEFT JOIN LATERAL (
    SELECT weight, date
    FROM weight_history
    WHERE user_id = u.user_id
    ORDER BY date DESC
    LIMIT 1
) wh ON TRUE;

-- =============================================================================
-- ФУНКЦІЇ ДЛЯ РОЗРАХУНКІВ
-- =============================================================================

-- Функція для розрахунку BMI
CREATE OR REPLACE FUNCTION fn_calculate_bmi(
    p_weight NUMERIC(5,2),
    p_height NUMERIC(5,2)
) RETURNS NUMERIC(4,2) AS $$
DECLARE
    v_height_m NUMERIC(4,2);
    v_bmi NUMERIC(4,2);
BEGIN
    v_height_m := p_height / 100;
    v_bmi := p_weight / (v_height_m * v_height_m);
    
    RETURN ROUND(v_bmi, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Функція для визначення категорії BMI
CREATE OR REPLACE FUNCTION fn_get_bmi_category(
    p_bmi NUMERIC(4,2)
) RETURNS VARCHAR(50) AS $$
DECLARE
    v_category VARCHAR(50);
BEGIN
    IF p_bmi < 18.5 THEN
        v_category := 'Недостатня вага';
    ELSIF p_bmi >= 18.5 AND p_bmi < 25 THEN
        v_category := 'Нормальна вага';
    ELSIF p_bmi >= 25 AND p_bmi < 30 THEN
        v_category := 'Надлишкова вага';
    ELSIF p_bmi >= 30 AND p_bmi < 35 THEN
        v_category := 'Ожиріння I ступеня';
    ELSIF p_bmi >= 35 AND p_bmi < 40 THEN
        v_category := 'Ожиріння II ступеня';
    ELSE
        v_category := 'Ожиріння III ступеня';
    END IF;
    
    RETURN v_category;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Функція для розрахунку BMR (Basal Metabolic Rate) за формулою Mifflin-St Jeor
CREATE OR REPLACE FUNCTION fn_calculate_bmr(
    p_weight NUMERIC(5,2),
    p_height NUMERIC(5,2),
    p_age INTEGER,
    p_gender gender_type
) RETURNS NUMERIC(7,2) AS $$
DECLARE
    v_bmr NUMERIC(7,2);
BEGIN
    -- Формула Mifflin-St Jeor
    -- Для чоловіків: BMR = (10 × вага в кг) + (6.25 × зріст в см) - (5 × вік) + 5
    -- Для жінок: BMR = (10 × вага в кг) + (6.25 × зріст в см) - (5 × вік) - 161
    
    v_bmr := (10 * p_weight) + (6.25 * p_height) - (5 * p_age);
    
    IF p_gender = 'MALE' THEN
        v_bmr := v_bmr + 5;
    ELSE
        v_bmr := v_bmr - 161;
    END IF;
    
    RETURN ROUND(v_bmr, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Функція для розрахунку TDEE (Total Daily Energy Expenditure)
CREATE OR REPLACE FUNCTION fn_calculate_tdee(
    p_bmr NUMERIC(7,2),
    p_activity_level activity_level_type
) RETURNS NUMERIC(7,2) AS $$
DECLARE
    v_multiplier NUMERIC(3,2);
    v_tdee NUMERIC(7,2);
BEGIN
    -- Множники активності
    CASE p_activity_level
        WHEN 'MINIMAL' THEN v_multiplier := 1.2;      -- Сидячий спосіб життя
        WHEN 'LOW' THEN v_multiplier := 1.375;        -- Легкі вправи 1-3 дні/тиждень
        WHEN 'MODERATE' THEN v_multiplier := 1.55;    -- Помірні вправи 3-5 днів/тиждень
        WHEN 'HIGH' THEN v_multiplier := 1.725;       -- Інтенсивні вправи 6-7 днів/тиждень
        WHEN 'VERY_HIGH' THEN v_multiplier := 1.9;    -- Дуже інтенсивні вправи, фізична робота
    END CASE;
    
    v_tdee := p_bmr * v_multiplier;
    
    RETURN ROUND(v_tdee, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =============================================================================
-- ЗБЕРЕЖЕНІ ПРОЦЕДУРИ
-- =============================================================================

-- Процедура для отримання статистики користувача за період
CREATE OR REPLACE FUNCTION sp_get_user_statistics(
    p_user_id BIGINT,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    stat_date DATE,
    total_calories NUMERIC(7,2),
    total_protein NUMERIC(6,2),
    total_fat NUMERIC(6,2),
    total_carbs NUMERIC(6,2),
    goal_achieved BOOLEAN,
    goal_percentage NUMERIC(5,2),
    breakfast_calories NUMERIC(7,2),
    lunch_calories NUMERIC(7,2),
    dinner_calories NUMERIC(7,2),
    snack_calories NUMERIC(7,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ds.date,
        ds.total_calories,
        ds.total_protein,
        ds.total_fat,
        ds.total_carbs,
        ds.goal_achieved,
        ds.goal_percentage,
        ds.breakfast_calories,
        ds.lunch_calories,
        ds.dinner_calories,
        ds.snack_calories
    FROM daily_summary ds
    WHERE ds.user_id = p_user_id 
        AND ds.date BETWEEN p_start_date AND p_end_date
    ORDER BY ds.date DESC;
END;
$$ LANGUAGE plpgsql;

-- Процедура для очищення старих токенів
CREATE OR REPLACE FUNCTION sp_cleanup_expired_tokens()
RETURNS TABLE (
    deleted_tokens INTEGER,
    deactivated_sessions INTEGER
) AS $$
DECLARE
    v_deleted_tokens INTEGER;
    v_deactivated_sessions INTEGER;
BEGIN
    -- Видалення прострочених токенів відновлення паролю
    DELETE FROM password_reset_tokens
    WHERE expires_at < CURRENT_TIMESTAMP;
    
    GET DIAGNOSTICS v_deleted_tokens = ROW_COUNT;
    
    -- Деактивація прострочених сесій
    UPDATE user_sessions
    SET is_active = FALSE
    WHERE refresh_token_expires_at < CURRENT_TIMESTAMP
        AND is_active = TRUE;
    
    GET DIAGNOSTICS v_deactivated_sessions = ROW_COUNT;
    
    RETURN QUERY SELECT v_deleted_tokens, v_deactivated_sessions;
END;
$$ LANGUAGE plpgsql;

-- Процедура для додавання запису в щоденник харчування
CREATE OR REPLACE FUNCTION sp_add_food_diary_entry(
    p_user_id BIGINT,
    p_product_id BIGINT,
    p_meal_type_id INTEGER,
    p_date DATE,
    p_time TIME,
    p_weight_grams NUMERIC(7,2),
    p_notes TEXT DEFAULT NULL
)
RETURNS TABLE (
    diary_entry_id BIGINT,
    calculated_calories NUMERIC(7,2),
    calculated_protein NUMERIC(6,2),
    calculated_fat NUMERIC(6,2),
    calculated_carbs NUMERIC(6,2)
) AS $$
DECLARE
    v_diary_entry_id BIGINT;
    v_calories NUMERIC(7,2);
    v_protein NUMERIC(6,2);
    v_fat NUMERIC(6,2);
    v_carbs NUMERIC(6,2);
BEGIN
    -- Розрахунок харчової цінності на основі ваги
    SELECT 
        (calories_per_100g * p_weight_grams / 100),
        (protein_per_100g * p_weight_grams / 100),
        (fat_per_100g * p_weight_grams / 100),
        (carbs_per_100g * p_weight_grams / 100)
    INTO v_calories, v_protein, v_fat, v_carbs
    FROM products
    WHERE product_id = p_product_id;
    
    -- Перевірка, чи знайдено продукт
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Продукт з ID % не знайдено', p_product_id;
    END IF;
    
    -- Вставка запису
    INSERT INTO food_diary (
        user_id, product_id, meal_type_id, date, time,
        weight_grams, calories, protein, fat, carbs, notes
    ) VALUES (
        p_user_id, p_product_id, p_meal_type_id, p_date, p_time,
        p_weight_grams, v_calories, v_protein, v_fat, v_carbs, p_notes
    )
    RETURNING food_diary.diary_entry_id INTO v_diary_entry_id;
    
    RETURN QUERY SELECT 
        v_diary_entry_id,
        v_calories,
        v_protein,
        v_fat,
        v_carbs;
END;
$$ LANGUAGE plpgsql;

-- Процедура для додавання запису про вагу
CREATE OR REPLACE FUNCTION sp_add_weight_entry(
    p_user_id BIGINT,
    p_date DATE,
    p_weight NUMERIC(5,2),
    p_notes TEXT DEFAULT NULL
)
RETURNS TABLE (
    weight_entry_id BIGINT,
    calculated_bmi NUMERIC(4,2),
    bmi_category VARCHAR(50)
) AS $$
DECLARE
    v_weight_entry_id BIGINT;
    v_height NUMERIC(5,2);
    v_bmi NUMERIC(4,2);
    v_bmi_category VARCHAR(50);
BEGIN
    -- Отримання зросту користувача
    SELECT height INTO v_height
    FROM users
    WHERE user_id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Користувача з ID % не знайдено', p_user_id;
    END IF;
    
    -- Розрахунок BMI
    v_bmi := fn_calculate_bmi(p_weight, v_height);
    v_bmi_category := fn_get_bmi_category(v_bmi);
    
    -- Вставка запису
    INSERT INTO weight_history (user_id, date, weight, bmi, notes)
    VALUES (p_user_id, p_date, p_weight, v_bmi, p_notes)
    ON CONFLICT (user_id, date) 
    DO UPDATE SET 
        weight = EXCLUDED.weight,
        bmi = EXCLUDED.bmi,
        notes = EXCLUDED.notes
    RETURNING weight_history.weight_entry_id INTO v_weight_entry_id;
    
    -- Оновлення поточної ваги та BMI користувача
    UPDATE users
    SET 
        current_weight = p_weight,
        bmi = v_bmi,
        bmi_category = v_bmi_category,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id;
    
    RETURN QUERY SELECT 
        v_weight_entry_id,
        v_bmi,
        v_bmi_category;
END;
$$ LANGUAGE plpgsql;

-- Процедура для створення користувача з автоматичними розрахунками
CREATE OR REPLACE FUNCTION sp_create_user(
    p_email VARCHAR(255),
    p_password_hash VARCHAR(255),
    p_first_name VARCHAR(50),
    p_last_name VARCHAR(50),
    p_date_of_birth DATE,
    p_gender gender_type,
    p_height NUMERIC(5,2),
    p_current_weight NUMERIC(5,2),
    p_target_weight NUMERIC(5,2),
    p_activity_level activity_level_type
)
RETURNS TABLE (
    user_id BIGINT,
    calculated_age INTEGER,
    calculated_bmr NUMERIC(7,2),
    calculated_tdee NUMERIC(7,2),
    calculated_bmi NUMERIC(4,2),
    bmi_category VARCHAR(50)
) AS $$
DECLARE
    v_user_id BIGINT;
    v_age INTEGER;
    v_bmr NUMERIC(7,2);
    v_tdee NUMERIC(7,2);
    v_bmi NUMERIC(4,2);
    v_bmi_category VARCHAR(50);
BEGIN
    -- Розрахунок віку
    v_age := EXTRACT(YEAR FROM AGE(CURRENT_DATE, p_date_of_birth));
    
    -- Розрахунок BMR
    v_bmr := fn_calculate_bmr(p_current_weight, p_height, v_age, p_gender);
    
    -- Розрахунок TDEE
    v_tdee := fn_calculate_tdee(v_bmr, p_activity_level);
    
    -- Розрахунок BMI
    v_bmi := fn_calculate_bmi(p_current_weight, p_height);
    v_bmi_category := fn_get_bmi_category(v_bmi);
    
    -- Вставка користувача
    INSERT INTO users (
        email, password_hash, first_name, last_name, date_of_birth,
        age, gender, height, current_weight, target_weight,
        activity_level, bmr, tdee, bmi, bmi_category
    ) VALUES (
        p_email, p_password_hash, p_first_name, p_last_name, p_date_of_birth,
        v_age, p_gender, p_height, p_current_weight, p_target_weight,
        p_activity_level, v_bmr, v_tdee, v_bmi, v_bmi_category
    )
    RETURNING users.user_id INTO v_user_id;
    
    -- Створення налаштувань за замовчуванням
    INSERT INTO user_settings (user_id)
    VALUES (v_user_id);
    
    RETURN QUERY SELECT 
        v_user_id,
        v_age,
        v_bmr,
        v_tdee,
        v_bmi,
        v_bmi_category;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- ДОДАТКОВІ КОРИСНІ ФУНКЦІЇ
-- =============================================================================

-- Функція для отримання прогресу користувача за період
CREATE OR REPLACE FUNCTION fn_get_weight_progress(
    p_user_id BIGINT,
    p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
    date DATE,
    weight NUMERIC(5,2),
    bmi NUMERIC(4,2),
    weight_change NUMERIC(5,2),
    days_from_start INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH weight_data AS (
        SELECT 
            wh.date,
            wh.weight,
            wh.bmi,
            LAG(wh.weight) OVER (ORDER BY wh.date) as prev_weight,
            EXTRACT(DAY FROM wh.date - MIN(wh.date) OVER ())::INTEGER as days_from_start
        FROM weight_history wh
        WHERE wh.user_id = p_user_id
            AND wh.date >= CURRENT_DATE - p_days
        ORDER BY wh.date
    )
    SELECT 
        wd.date,
        wd.weight,
        wd.bmi,
        COALESCE(wd.weight - wd.prev_weight, 0) as weight_change,
        wd.days_from_start
    FROM weight_data wd;
END;
$$ LANGUAGE plpgsql;

-- Функція для отримання статистики споживання за категоріями продуктів
CREATE OR REPLACE FUNCTION fn_get_category_statistics(
    p_user_id BIGINT,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    category product_category_type,
    total_calories NUMERIC(10,2),
    total_protein NUMERIC(10,2),
    total_fat NUMERIC(10,2),
    total_carbs NUMERIC(10,2),
    entry_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.category,
        SUM(fd.calories)::NUMERIC(10,2),
        SUM(fd.protein)::NUMERIC(10,2),
        SUM(fd.fat)::NUMERIC(10,2),
        SUM(fd.carbs)::NUMERIC(10,2),
        COUNT(*)
    FROM food_diary fd
    INNER JOIN products p ON fd.product_id = p.product_id
    WHERE fd.user_id = p_user_id
        AND fd.date BETWEEN p_start_date AND p_end_date
    GROUP BY p.category
    ORDER BY SUM(fd.calories) DESC;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- КОМЕНТАРІ ДО ТАБЛИЦЬ ТА КОЛОНОК
-- =============================================================================

COMMENT ON DATABASE stayfit_db IS 'База даних для системи контролю харчування StayFit';

COMMENT ON TABLE users IS 'Основна таблиця користувачів системи';
COMMENT ON TABLE user_settings IS 'Персональні налаштування користувачів (зв''язок 1:1)';
COMMENT ON TABLE user_goals IS 'Цілі харчування користувачів';
COMMENT ON TABLE products IS 'Глобальна база продуктів харчування';
COMMENT ON TABLE meal_types IS 'Довідник типів прийомів їжі';
COMMENT ON TABLE food_diary IS 'Щоденник харчування користувачів';
COMMENT ON TABLE weight_history IS 'Історія вимірювань ваги';
COMMENT ON TABLE user_sessions IS 'Активні сесії користувачів (JWT токени)';
COMMENT ON TABLE password_reset_tokens IS 'Токени для відновлення паролю';
COMMENT ON TABLE activity_log IS 'Журнал активності системи';
COMMENT ON TABLE daily_summary IS 'Агреговані щоденні підсумки харчування';
COMMENT ON TABLE recipes IS 'Користувацькі рецепти';
COMMENT ON TABLE recipe_ingredients IS 'Інгредієнти рецептів';

-- =============================================================================
-- ІНФОРМАЦІЯ ПРО КАСКАДНІ ВИДАЛЕННЯ
-- =============================================================================

/*
КАСКАДНІ ВИДАЛЕННЯ В СИСТЕМІ:

1. users → user_settings (CASCADE)
   При видаленні користувача автоматично видаляються його налаштування

2. users → user_goals (CASCADE)
   При видаленні користувача автоматично видаляються всі його цілі

3. users → food_diary (CASCADE)
   При видаленні користувача автоматично видаляються всі записи в щоденнику

4. users → weight_history (CASCADE)
   При видаленні користувача автоматично видаляється історія ваги

5. users → user_sessions (CASCADE)
   При видаленні користувача автоматично видаляються всі сесії

6. users → password_reset_tokens (CASCADE)
   При видаленні користувача автоматично видаляються токени відновлення

7. users → daily_summary (CASCADE)
   При видаленні користувача автоматично видаляються щоденні підсумки

8. users → recipes (CASCADE)
   При видаленні користувача автоматично видаляються його рецепти

9. recipes → recipe_ingredients (CASCADE)
   При видаленні рецепту автоматично видаляються всі його інгредієнти

10. users → products (SET NULL для created_by_user_id)
    При видаленні користувача його продукти залишаються, але автор стає NULL

11. users → activity_log (SET NULL)
    При видаленні користувача логи зберігаються, але user_id стає NULL

ОБМЕЖЕННЯ НА ВИДАЛЕННЯ (RESTRICT):

1. products → food_diary (RESTRICT)
   Не можна видалити продукт, якщо він використовується в щоденнику

2. products → recipe_ingredients (RESTRICT)
   Не можна видалити продукт, якщо він є інгредієнтом рецепту

3. meal_types → food_diary (RESTRICT)
   Не можна видалити тип прийому їжі, якщо він використовується
*/

-- =============================================================================
-- ЗАВЕРШЕННЯ СТВОРЕННЯ БАЗИ ДАНИХ
-- =============================================================================

-- Вивід інформації про створені таблиці
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;