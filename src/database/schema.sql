-- Domains
CREATE DOMAIN email_domain AS VARCHAR(255)
    CHECK (VALUE ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

CREATE DOMAIN password_hash_domain AS VARCHAR(255)
    CHECK (LENGTH(VALUE) >= 60);

CREATE DOMAIN person_name_domain AS VARCHAR(50)
    CHECK (LENGTH(TRIM(VALUE)) >= 2 AND VALUE ~ '^[А-ЯҐа-яґІіЇїЄєҐґA-Za-z ''-]+$');

CREATE DOMAIN age_domain AS INT
    CHECK (VALUE >= 13 AND VALUE <= 120);

CREATE DOMAIN height_domain AS DECIMAL(5,2)
    CHECK (VALUE >= 50.00 AND VALUE <= 300.00);

CREATE DOMAIN weight_domain AS DECIMAL(5,2)
    CHECK (VALUE >= 20.00 AND VALUE <= 500.00);

CREATE DOMAIN bmi_domain AS DECIMAL(4,2)
    CHECK (VALUE >= 10.00 AND VALUE <= 100.00);

CREATE DOMAIN calories_domain AS DECIMAL(7,2)
    CHECK (VALUE >= 0 AND VALUE <= 10000.00);

CREATE DOMAIN macros_domain AS DECIMAL(6,2)
    CHECK (VALUE >= 0 AND VALUE <= 1000.00);

CREATE DOMAIN product_name_domain AS VARCHAR(255)
    CHECK (LENGTH(TRIM(VALUE)) >= 2);

CREATE DOMAIN weight_grams_domain AS DECIMAL(7,2)
    CHECK (VALUE > 0 AND VALUE <= 10000.00);

CREATE DOMAIN token_code_domain AS VARCHAR(6)
    CHECK (VALUE ~ '^[0-9]{6}$');

CREATE DOMAIN language_code_domain AS VARCHAR(10)
    CHECK (VALUE IN ('uk', 'en'));

-- Tables
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email email_domain UNIQUE NOT NULL,
    password_hash password_hash_domain NOT NULL,
    first_name person_name_domain NOT NULL,
    last_name person_name_domain NOT NULL,
    date_of_birth DATE NOT NULL 
        CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '13 years' 
           AND date_of_birth >= CURRENT_DATE - INTERVAL '120 years'),
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('MALE', 'FEMALE')),
    height height_domain,
    current_weight weight_domain,
    target_weight weight_domain 
        CHECK (target_weight IS NULL OR target_weight != current_weight),
    activity_level VARCHAR(20) NOT NULL 
        CHECK (activity_level IN ('SEDENTARY', 'LIGHTLY_ACTIVE', 'MODERATELY_ACTIVE', 'VERY_ACTIVE', 'EXTRA_ACTIVE')),
    role VARCHAR(10) DEFAULT 'USER' NOT NULL 
        CHECK (role IN ('USER', 'ADMIN', 'GUEST')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE user_goals (
    goal_id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    daily_calories calories_domain NOT NULL 
        CHECK (daily_calories >= 800 AND daily_calories <= 10000),
    goal_type VARCHAR(20) NOT NULL 
        CHECK (goal_type IN ('WEIGHT_LOSS', 'WEIGHT_GAIN', 'MAINTENANCE')),
    protein_grams macros_domain NOT NULL 
        CHECK (protein_grams >= 0 AND protein_grams <= 500),
    fat_grams macros_domain NOT NULL 
        CHECK (fat_grams >= 0 AND fat_grams <= 500),
    carbs_grams macros_domain NOT NULL 
        CHECK (carbs_grams >= 0 AND carbs_grams <= 1000),
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE user_settings (
    settings_id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    language language_code_domain DEFAULT 'uk' NOT NULL,
    theme VARCHAR(10) DEFAULT 'LIGHT' NOT NULL 
        CHECK (theme IN ('LIGHT', 'DARK', 'AUTO')),
    reminder_food_enabled BOOLEAN DEFAULT FALSE NOT NULL,
    weekly_reports_enabled BOOLEAN DEFAULT TRUE NOT NULL
);

CREATE TABLE meal_types (
    meal_type_id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL 
        CHECK (name IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK')),
    display_order INTEGER UNIQUE NOT NULL 
        CHECK (display_order >= 1 AND display_order <= 10)
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name product_name_domain NOT NULL,
    category VARCHAR(20) NOT NULL 
        CHECK (category IN ('VEGETABLES', 'FRUITS', 'MEAT', 'FISH', 'DAIRY', 'GRAINS', 'SNACKS', 'BEVERAGES', 'OTHER')),
    calories_per_100g calories_domain NOT NULL 
        CHECK (calories_per_100g >= 0 AND calories_per_100g <= 900),
    protein_per_100g macros_domain NOT NULL 
        CHECK (protein_per_100g >= 0 AND protein_per_100g <= 100),
    fat_per_100g macros_domain NOT NULL 
        CHECK (fat_per_100g >= 0 AND fat_per_100g <= 100),
    carbs_per_100g macros_domain NOT NULL 
        CHECK (carbs_per_100g >= 0 AND carbs_per_100g <= 100),
    is_global BOOLEAN DEFAULT TRUE NOT NULL,
    created_by_user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE food_diary (
    diary_entry_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    meal_type_id INTEGER NOT NULL REFERENCES meal_types(meal_type_id) ON DELETE RESTRICT,
    date DATE NOT NULL 
        CHECK (date <= CURRENT_DATE AND date >= '2020-01-01'),
    time TIME NOT NULL,
    weight_grams weight_grams_domain NOT NULL,
    calories calories_domain NOT NULL,
    protein macros_domain NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE weight_history (
    weight_entry_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    date DATE NOT NULL 
        CHECK (date <= CURRENT_DATE AND date >= '2020-01-01'),
    weight weight_domain NOT NULL,
    bmi bmi_domain NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (user_id, date)
);

CREATE TABLE daily_summary (
    summary_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    date DATE NOT NULL 
        CHECK (date <= CURRENT_DATE AND date >= '2020-01-01'),
    total_calories calories_domain DEFAULT 0 NOT NULL,
    total_protein macros_domain DEFAULT 0 NOT NULL,
    goal_achieved BOOLEAN DEFAULT FALSE NOT NULL,
    breakfast_calories calories_domain DEFAULT 0 NOT NULL,
    lunch_calories calories_domain DEFAULT 0 NOT NULL,
    dinner_calories calories_domain DEFAULT 0 NOT NULL,
    UNIQUE (user_id, date)
);

CREATE TABLE user_sessions (
    session_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    access_token_hash VARCHAR(255) UNIQUE NOT NULL 
        CHECK (LENGTH(access_token_hash) >= 32),
    refresh_token_hash VARCHAR(255) UNIQUE NOT NULL 
        CHECK (LENGTH(refresh_token_hash) >= 32),
    device_info VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    access_token_expires_at TIMESTAMP NOT NULL 
        CHECK (access_token_expires_at > created_at)
);

CREATE TABLE password_reset_tokens (
    token_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token_code token_code_domain NOT NULL,
    is_used BOOLEAN DEFAULT FALSE NOT NULL,
    attempts INTEGER DEFAULT 0 NOT NULL 
        CHECK (attempts >= 0 AND attempts <= 10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NOT NULL 
        CHECK (expires_at > created_at)
);

CREATE TABLE activity_log (
    log_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    action_type VARCHAR(100) NOT NULL 
        CHECK (LENGTH(action_type) >= 3),
    description TEXT,
    status VARCHAR(10) DEFAULT 'SUCCESS' NOT NULL 
        CHECK (status IN ('SUCCESS', 'FAILURE', 'WARNING')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);
