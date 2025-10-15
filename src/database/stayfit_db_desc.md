# Опис бази даних StayFit

## Домени

```sql
CREATE DOMAIN email_domain AS VARCHAR(255)
    CHECK (VALUE ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

CREATE DOMAIN password_hash_domain AS VARCHAR(255)
    CHECK (LENGTH(VALUE) >= 60);

CREATE DOMAIN person_name_domain AS VARCHAR(50)
    CHECK (LENGTH(TRIM(VALUE)) >= 2 AND VALUE ~ '^[А-Яа-яІіЇїЄєҐґA-Za-z ''-]+$');

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
    CHECK (VALUE IN ('uk', 'en', 'ru'));
```

---

## 1. Users (Користувачі)

**Опис:** Інформація про зареєстрованих користувачів системи.

| Атрибут        | Тип даних                      | Опис                                                                                                                           |
| -------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| user_id        | INT                            | PRIMARY KEY, AUTO_INCREMENT                                                                                                    |
| email          | email_domain                   | UNIQUE, INDEX, NOT NULL                                                                                                        |
| password_hash  | password_hash_domain           | NOT NULL                                                                                                                       |
| first_name     | person_name_domain             | NOT NULL                                                                                                                       |
| last_name      | person_name_domain             | NOT NULL                                                                                                                       |
| date_of_birth  | DATE                           | NOT NULL, CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '13 years' AND date_of_birth >= CURRENT_DATE - INTERVAL '120 years') |
| gender         | ENUM('MALE', 'FEMALE')         | NOT NULL                                                                                                                       |
| height         | height_domain                  | NULL                                                                                                                           |
| current_weight | weight_domain                  | NULL                                                                                                                           |
| target_weight  | weight_domain                  | NULL, CHECK (target_weight IS NULL OR target_weight != current_weight)                                                         |
| activity_level | ENUM                           | NOT NULL, CHECK (activity_level IN ('SEDENTARY', 'LIGHTLY_ACTIVE', 'MODERATELY_ACTIVE', 'VERY_ACTIVE', 'EXTRA_ACTIVE'))        |
| role           | ENUM('USER', 'ADMIN', 'GUEST') | DEFAULT 'USER', NOT NULL                                                                                                       |
| created_at     | TIMESTAMP                      | DEFAULT CURRENT_TIMESTAMP, NOT NULL                                                                                            |

---

## 2. UserGoals (Цілі харчування)

**Опис:** Персональні цілі харчування користувача.

| Атрибут        | Тип даних                                         | Опис                                                                |
| -------------- | ------------------------------------------------- | ------------------------------------------------------------------- |
| goal_id        | INT                                               | PRIMARY KEY, AUTO_INCREMENT                                         |
| user_id        | INT                                               | FOREIGN KEY → Users.user_id, UNIQUE, NOT NULL                       |
| daily_calories | calories_domain                                   | NOT NULL, CHECK (daily_calories >= 800 AND daily_calories <= 10000) |
| goal_type      | ENUM('WEIGHT_LOSS', 'WEIGHT_GAIN', 'MAINTENANCE') | NOT NULL                                                            |
| protein_grams  | macros_domain                                     | NOT NULL, CHECK (protein_grams >= 0 AND protein_grams <= 500)       |
| fat_grams      | macros_domain                                     | NOT NULL, CHECK (fat_grams >= 0 AND fat_grams <= 500)               |
| carbs_grams    | macros_domain                                     | NOT NULL, CHECK (carbs_grams >= 0 AND carbs_grams <= 1000)          |
| is_active      | BOOLEAN                                           | DEFAULT TRUE, NOT NULL                                              |
| created_at     | TIMESTAMP                                         | DEFAULT CURRENT_TIMESTAMP, NOT NULL                                 |

**Зв'язок:** Users (1:1) UserGoals | CASCADE

---

## 3. UserSettings (Налаштування)

**Опис:** Персональні налаштування додатку.

| Атрибут                | Тип даних                     | Опис                                           |
| ---------------------- | ----------------------------- | ---------------------------------------------- |
| settings_id            | INT                           | PRIMARY KEY, AUTO_INCREMENT                    |
| user_id                | INT                           | FOREIGN KEY → Users.user_id (UNIQUE), NOT NULL |
| language               | language_code_domain          | DEFAULT 'uk', NOT NULL                         |
| theme                  | ENUM('LIGHT', 'DARK', 'AUTO') | DEFAULT 'LIGHT', NOT NULL                      |
| reminder_food_enabled  | BOOLEAN                       | DEFAULT FALSE, NOT NULL                        |
| weekly_reports_enabled | BOOLEAN                       | DEFAULT TRUE, NOT NULL                         |

**Зв'язок:** Users (1:1) UserSettings | CASCADE

---

## 4. Products (База продуктів)

**Опис:** Глобальна таблиця продуктів з харчовою цінністю.

| Атрибут            | Тип даних           | Опис                                                                                                                             |
| ------------------ | ------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| product_id         | INT                 | PRIMARY KEY, AUTO_INCREMENT                                                                                                      |
| name               | product_name_domain | INDEX, NOT NULL                                                                                                                  |
| category           | ENUM                | NOT NULL, INDEX, CHECK (category IN ('VEGETABLES', 'FRUITS', 'MEAT', 'FISH', 'DAIRY', 'GRAINS', 'SNACKS', 'BEVERAGES', 'OTHER')) |
| calories_per_100g  | calories_domain     | NOT NULL, CHECK (calories_per_100g >= 0 AND calories_per_100g <= 900)                                                            |
| protein_per_100g   | macros_domain       | NOT NULL, CHECK (protein_per_100g >= 0 AND protein_per_100g <= 100)                                                              |
| fat_per_100g       | macros_domain       | NOT NULL, CHECK (fat_per_100g >= 0 AND fat_per_100g <= 100)                                                                      |
| carbs_per_100g     | macros_domain       | NOT NULL, CHECK (carbs_per_100g >= 0 AND carbs_per_100g <= 100)                                                                  |
| is_global          | BOOLEAN             | DEFAULT TRUE, NOT NULL                                                                                                           |
| created_by_user_id | INT                 | FOREIGN KEY → Users.user_id, NULL                                                                                                |
| created_at         | TIMESTAMP           | DEFAULT CURRENT_TIMESTAMP, NOT NULL                                                                                              |

**Зв'язок:** Users (1:N) Products | SET NULL

---

## 5. FoodDiary (Щоденник харчування)

**Опис:** Записи про спожиті продукти.

| Атрибут        | Тип даних           | Опис                                                                   |
| -------------- | ------------------- | ---------------------------------------------------------------------- |
| diary_entry_id | INT                 | PRIMARY KEY, AUTO_INCREMENT                                            |
| user_id        | INT                 | FOREIGN KEY → Users.user_id, INDEX, NOT NULL                           |
| product_id     | INT                 | FOREIGN KEY → Products.product_id, NOT NULL                            |
| meal_type_id   | INT                 | FOREIGN KEY → MealTypes.meal_type_id, NOT NULL                         |
| date           | DATE                | INDEX, NOT NULL, CHECK (date <= CURRENT_DATE AND date >= '2020-01-01') |
| time           | TIME                | NOT NULL                                                               |
| weight_grams   | weight_grams_domain | NOT NULL                                                               |
| calories       | calories_domain     | NOT NULL                                                               |
| protein        | macros_domain       | NOT NULL                                                               |
| created_at     | TIMESTAMP           | DEFAULT CURRENT_TIMESTAMP, NOT NULL                                    |

**Зв'язки:**

- Users (1:N) FoodDiary | CASCADE
- Products (1:N) FoodDiary | RESTRICT
- MealTypes (1:N) FoodDiary | RESTRICT

**Індекс:** (user_id, date)

---

## 6. MealTypes (Типи прийомів їжі)

**Опис:** Довідник типів прийомів їжі.

| Атрибут       | Тип даних   | Опис                                                                        |
| ------------- | ----------- | --------------------------------------------------------------------------- |
| meal_type_id  | INT         | PRIMARY KEY, AUTO_INCREMENT                                                 |
| name          | VARCHAR(50) | UNIQUE, NOT NULL, CHECK (name IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK')) |
| display_order | INT         | NOT NULL, CHECK (display_order >= 1 AND display_order <= 10), UNIQUE        |

---

## 7. WeightHistory (Історія ваги)

**Опис:** Динаміка зміни ваги користувача.

| Атрибут         | Тип daних     | Опис                                                                   |
| --------------- | ------------- | ---------------------------------------------------------------------- |
| weight_entry_id | INT           | PRIMARY KEY, AUTO_INCREMENT                                            |
| user_id         | INT           | FOREIGN KEY → Users.user_id, INDEX, NOT NULL                           |
| date            | DATE          | INDEX, NOT NULL, CHECK (date <= CURRENT_DATE AND date >= '2020-01-01') |
| weight          | weight_domain | NOT NULL                                                               |
| bmi             | bmi_domain    | NOT NULL                                                               |
| created_at      | TIMESTAMP     | DEFAULT CURRENT_TIMESTAMP, NOT NULL                                    |

**Зв'язок:** Users (1:N) WeightHistory | CASCADE

**Індекс:** UNIQUE (user_id, date)

---

## 8. DailySummary (Щоденні підсумки)

**Опис:** Агреговані дані за день.

| Атрибут            | Тип даних       | Опис                                                                   |
| ------------------ | --------------- | ---------------------------------------------------------------------- |
| summary_id         | INT             | PRIMARY KEY, AUTO_INCREMENT                                            |
| user_id            | INT             | FOREIGN KEY → Users.user_id, INDEX, NOT NULL                           |
| date               | DATE            | INDEX, NOT NULL, CHECK (date <= CURRENT_DATE AND date >= '2020-01-01') |
| total_calories     | calories_domain | NOT NULL, DEFAULT 0                                                    |
| total_protein      | macros_domain   | NOT NULL, DEFAULT 0                                                    |
| goal_achieved      | BOOLEAN         | NOT NULL, DEFAULT FALSE                                                |
| breakfast_calories | calories_domain | NOT NULL, DEFAULT 0                                                    |
| lunch_calories     | calories_domain | NOT NULL, DEFAULT 0                                                    |
| dinner_calories    | calories_domain | NOT NULL, DEFAULT 0                                                    |

**Зв'язок:** Users (1:N) DailySummary | CASCADE

**Індекс:** UNIQUE (user_id, date)

---

## 9. UserSessions (Сесії користувачів)

**Опис:** Активні сесії користувачів (JWT).

| Атрибут                 | Тип даних    | Опис                                                       |
| ----------------------- | ------------ | ---------------------------------------------------------- |
| session_id              | INT          | PRIMARY KEY, AUTO_INCREMENT                                |
| user_id                 | INT          | FOREIGN KEY → Users.user_id, INDEX, NOT NULL               |
| access_token_hash       | VARCHAR(255) | UNIQUE, NOT NULL, CHECK (LENGTH(access_token_hash) >= 32)  |
| refresh_token_hash      | VARCHAR(255) | UNIQUE, NOT NULL, CHECK (LENGTH(refresh_token_hash) >= 32) |
| device_info             | VARCHAR(500) | NULL                                                       |
| is_active               | BOOLEAN      | DEFAULT TRUE, NOT NULL                                     |
| created_at              | TIMESTAMP    | DEFAULT CURRENT_TIMESTAMP, NOT NULL                        |
| access_token_expires_at | TIMESTAMP    | NOT NULL, CHECK (access_token_expires_at > created_at)     |

**Зв'язок:** Users (1:N) UserSessions | CASCADE

---

## 10. PasswordResetTokens (Токени відновлення)

**Опис:** Токени для відновлення паролю.

| Атрибут    | Тип даних         | Опис                                                          |
| ---------- | ----------------- | ------------------------------------------------------------- |
| token_id   | INT               | PRIMARY KEY, AUTO_INCREMENT                                   |
| user_id    | INT               | FOREIGN KEY → Users.user_id, INDEX, NOT NULL                  |
| token_code | token_code_domain | INDEX, NOT NULL                                               |
| is_used    | BOOLEAN           | DEFAULT FALSE, NOT NULL                                       |
| attempts   | INT               | DEFAULT 0, NOT NULL, CHECK (attempts >= 0 AND attempts <= 10) |
| created_at | TIMESTAMP         | DEFAULT CURRENT_TIMESTAMP, NOT NULL                           |
| expires_at | TIMESTAMP         | NOT NULL, CHECK (expires_at > created_at)                     |

**Зв'язок:** Users (1:N) PasswordResetTokens | CASCADE

---

## 11. ActivityLog (Логи активності)

**Опис:** Логи дій користувачів та адміністраторів.

| Атрибут     | Тип даних                             | Опис                                              |
| ----------- | ------------------------------------- | ------------------------------------------------- |
| log_id      | INT                                   | PRIMARY KEY, AUTO_INCREMENT                       |
| user_id     | INT                                   | FOREIGN KEY → Users.user_id, INDEX, NULL          |
| action_type | VARCHAR(100)                          | INDEX, NOT NULL, CHECK (LENGTH(action_type) >= 3) |
| description | TEXT                                  | NULL                                              |
| status      | ENUM('SUCCESS', 'FAILURE', 'WARNING') | DEFAULT 'SUCCESS', NOT NULL                       |
| created_at  | TIMESTAMP                             | DEFAULT CURRENT_TIMESTAMP, INDEX, NOT NULL        |

**Зв'язок:** Users (1:N) ActivityLog | SET NULL

---

# Схема зв'язків

## 1:1 (One-to-One)

- **Users ↔ UserGoals** (CASCADE)
- **Users ↔ UserSettings** (CASCADE)

## 1:N (One-to-Many)

- **Users → FoodDiary** (CASCADE)
- **Users → WeightHistory** (CASCADE)
- **Users → DailySummary** (CASCADE)
- **Users → UserSessions** (CASCADE)
- **Users → PasswordResetTokens** (CASCADE)
- **Users → ActivityLog** (SET NULL)
- **Users → Products** (SET NULL)
- **Products → FoodDiary** (RESTRICT)
- **MealTypes → FoodDiary** (RESTRICT)

## N:M (Many-to-Many)

- **Users ↔ Products** (через FoodDiary)

---

# Ключові індекси

```sql
-- Пошук записів користувача
CREATE INDEX idx_food_diary_user_date ON FoodDiary (user_id, date);

-- Пошук продуктів
CREATE INDEX idx_products_name ON Products (name);
CREATE INDEX idx_products_category ON Products (category);

-- Сесії користувача
CREATE INDEX idx_sessions_user_active ON UserSessions (user_id, is_active);

-- Історія ваги
CREATE INDEX idx_weight_history_user_date ON WeightHistory (user_id, date DESC);

-- Логи активності
CREATE INDEX idx_activity_log_type_time ON ActivityLog (action_type, created_at DESC);

-- Email для швидкого пошуку
CREATE INDEX idx_users_email ON Users (email);

-- Активні цілі користувача
CREATE UNIQUE INDEX idx_user_goals_active ON UserGoals (user_id) WHERE (is_active = TRUE);
```

---

**Примітки:**

- Всього: 11 сутностей
- Всі дати/час в UTC
- Всі ENUM українською мовою
- Домени забезпечують уніфікацію та валідацію даних на рівні БД
- CHECK constraints гарантують цілісність даних
