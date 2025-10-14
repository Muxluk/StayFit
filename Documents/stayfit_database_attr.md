# Опис сутностей бази даних StayFit

На основі аналізу специфікації вимог до програмного забезпечення StayFit, визначено наступні основні сутності для бази даних:

---

## 1. Users (Користувачі)

**Опис:** Таблиця для зберігання інформації про зареєстрованих користувачів системи.

| Атрибут | Тип даних | Обов'язковість | Опис | Додаткові обмеження |
|---------|-----------|----------------|------|---------------------|
| user_id | INT / BIGINT | YES | Унікальний ідентифікатор користувача | PRIMARY KEY, AUTO_INCREMENT |
| email | VARCHAR(255) | YES | Email адреса користувача | UNIQUE, INDEX |
| password_hash | VARCHAR(255) | YES | Хешований пароль (bcrypt) | - |
| first_name | VARCHAR(50) | YES | Ім'я користувача | - |
| last_name | VARCHAR(50) | YES | Прізвище користувача | - |
| date_of_birth | DATE | YES | Дата народження | - |
| age | INT | YES | Вік користувача | CHECK (age >= 12 AND age <= 100) |
| gender | ENUM('MALE', 'FEMALE') | YES | Стать користувача | - |
| height | DECIMAL(5,2) | YES | Зріст у сантиметрах | CHECK (height >= 100 AND height <= 250) |
| current_weight | DECIMAL(5,2) | YES | Поточна вага у кілограмах | CHECK (current_weight >= 30 AND current_weight <= 300) |
| target_weight | DECIMAL(5,2) | YES | Цільова вага у кілограмах | CHECK (target_weight >= 30 AND target_weight <= 300) |
| activity_level | ENUM('MINIMAL', 'LOW', 'MODERATE', 'HIGH', 'VERY_HIGH') | YES | Рівень фізичної активності | - |
| bmr | DECIMAL(7,2) | YES | Базальний метаболізм (ккал/день) | - |
| tdee | DECIMAL(7,2) | YES | Загальні енергетичні витрати (ккал/день) | - |
| bmi | DECIMAL(4,2) | YES | Індекс маси тіла | - |
| bmi_category | VARCHAR(50) | YES | Категорія BMI | - |
| role | ENUM('USER', 'ADMIN', 'GUEST') | YES | Роль користувача | DEFAULT 'USER' |
| is_verified | BOOLEAN | YES | Чи верифікований email | DEFAULT FALSE |
| is_active | BOOLEAN | YES | Чи активний акаунт | DEFAULT TRUE |
| profile_photo_url | VARCHAR(500) | NO | URL фото профілю | - |
| created_at | TIMESTAMP | YES | Дата створення акаунту | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | YES | Дата останнього оновлення | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| last_login | TIMESTAMP | NO | Час останнього входу | - |

---

## 2. UserGoals (Цілі харчування користувача)

**Опис:** Таблиця для зберігання персональних цілей харчування та налаштувань користувача.

| Атрибут | Тип даних | Обов'язковість | Опис | Додаткові обмеження |
|---------|-----------|----------------|------|---------------------|
| goal_id | INT / BIGINT | YES | Унікальний ідентифікатор цілі | PRIMARY KEY, AUTO_INCREMENT |
| user_id | INT / BIGINT | YES | Ідентифікатор користувача | FOREIGN KEY (users.user_id) |
| daily_calories | DECIMAL(7,2) | YES | Щоденна норма калорій | CHECK (daily_calories > 0) |
| is_auto_calculated | BOOLEAN | YES | Автоматичний розрахунок калорій | DEFAULT TRUE |
| goal_type | ENUM('WEIGHT_LOSS', 'WEIGHT_GAIN', 'MAINTENANCE') | YES | Тип цілі | - |
| protein_grams | DECIMAL(6,2) | YES | Норма білків (грами) | CHECK (protein_grams >= 0) |
| fat_grams | DECIMAL(6,2) | YES | Норма жирів (грами) | CHECK (fat_grams >= 0) |
| carbs_grams | DECIMAL(6,2) | YES | Норма вуглеводів (грами) | CHECK (carbs_grams >= 0) |
| protein_percent | DECIMAL(5,2) | YES | Відсоток білків | CHECK (protein_percent >= 0 AND protein_percent <= 100) |
| fat_percent | DECIMAL(5,2) | YES | Відсоток жирів | CHECK (fat_percent >= 0 AND fat_percent <= 100) |
| carbs_percent | DECIMAL(5,2) | YES | Відсоток вуглеводів | CHECK (carbs_percent >= 0 AND carbs_percent <= 100) |
| meals_per_day | INT | YES | Кількість прийомів їжі на день | CHECK (meals_per_day >= 3 AND meals_per_day <= 6) |
| weight_change_rate | DECIMAL(4,2) | NO | Швидкість зміни ваги (кг/тиждень) | CHECK (weight_change_rate >= 0.25 AND weight_change_rate <= 1) |
| is_active | BOOLEAN | YES | Чи активна ціль | DEFAULT TRUE |
| created_at | TIMESTAMP | YES | Дата створення цілі | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | YES | Дата останнього оновлення | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

---

## 3. Products (База продуктів)

**Опис:** Глобальна таблиця продуктів з інформацією про харчову цінність.

| Атрибут | Тип даних | Обов'язковість | Опис | Додаткові обмеження |
|---------|-----------|----------------|------|---------------------|
| product_id | INT / BIGINT | YES | Унікальний ідентифікатор продукту | PRIMARY KEY, AUTO_INCREMENT |
| name | VARCHAR(255) | YES | Назва продукту | INDEX |
| category | ENUM('FRUITS', 'VEGETABLES', 'MEAT', 'DAIRY', 'GRAINS', 'BEVERAGES', 'SWEETS', 'FASTFOOD', 'OTHER') | YES | Категорія продукту | INDEX |
| calories_per_100g | DECIMAL(6,2) | YES | Калорії на 100г | CHECK (calories_per_100g >= 0) |
| protein_per_100g | DECIMAL(5,2) | YES | Білки на 100г | CHECK (protein_per_100g >= 0) |
| fat_per_100g | DECIMAL(5,2) | YES | Жири на 100г | CHECK (fat_per_100g >= 0) |
| carbs_per_100g | DECIMAL(5,2) | YES | Вуглеводи на 100г | CHECK (carbs_per_100g >= 0) |
| is_global | BOOLEAN | YES | Чи є продукт глобальним (доступний всім) | DEFAULT TRUE |
| created_by_user_id | INT / BIGINT | NO | ID користувача, який створив продукт | FOREIGN KEY (users.user_id) |
| is_approved | BOOLEAN | YES | Чи схвалений продукт адміністратором | DEFAULT FALSE |
| created_at | TIMESTAMP | YES | Дата додавання продукту | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | YES | Дата останнього оновлення | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

---

## 4. MealTypes (Типи прийомів їжі)

**Опис:** Довідникова таблиця типів прийомів їжі.

| Атрибут | Тип даних | Обов'язковість | Опис | Додаткові обмеження |
|---------|-----------|----------------|------|---------------------|
| meal_type_id | INT | YES | Унікальний ідентифікатор типу прийому їжі | PRIMARY KEY, AUTO_INCREMENT |
| name | VARCHAR(50) | YES | Назва прийому їжі | UNIQUE |
| display_order | INT | YES | Порядок відображення | - |
| default_time_start | TIME | NO | Рекомендований час початку | - |
| default_time_end | TIME | NO | Рекомендований час кінця | - |

**Дані за замовчуванням:**
- Сніданок (BREAKFAST) - 07:00-10:00
- Обід (LUNCH) - 12:00-15:00
- Вечеря (DINNER) - 18:00-21:00
- Перекус (SNACK) - будь-який час

---

## 5. FoodDiary (Щоденник харчування)

**Опис:** Таблиця для зберігання записів про спожиті продукти.

| Атрибут | Тип даних | Обов'язковість | Опис | Додаткові обмеження |
|---------|-----------|----------------|------|---------------------|
| diary_entry_id | INT / BIGINT | YES | Унікальний ідентифікатор запису | PRIMARY KEY, AUTO_INCREMENT |
| user_id | INT / BIGINT | YES | Ідентифікатор користувача | FOREIGN KEY (users.user_id), INDEX |
| product_id | INT / BIGINT | YES | Ідентифікатор продукту | FOREIGN KEY (products.product_id) |
| meal_type_id | INT | YES | Тип прийому їжі | FOREIGN KEY (meal_types.meal_type_id) |
| date | DATE | YES | Дата споживання | INDEX |
| time | TIME | YES | Час споживання | - |
| weight_grams | DECIMAL(7,2) | YES | Вага продукту в грамах | CHECK (weight_grams > 0) |
| calories | DECIMAL(7,2) | YES | Розраховані калорії | CHECK (calories >= 0) |
| protein | DECIMAL(6,2) | YES | Розраховані білки | CHECK (protein >= 0) |
| fat | DECIMAL(6,2) | YES | Розраховані жири | CHECK (fat >= 0) |
| carbs | DECIMAL(6,2) | YES | Розраховані вуглеводи | CHECK (carbs >= 0) |
| notes | TEXT | NO | Додаткові нотатки | - |
| created_at | TIMESTAMP | YES | Дата створення запису | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | YES | Дата останнього оновлення | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

**Індекси:**
- INDEX (user_id, date) - для швидкого пошуку записів користувача за датою
- INDEX (date) - для загальної статистики

---

## 6. WeightHistory (Історія ваги)

**Опис:** Таблиця для відстеження динаміки зміни ваги користувача.

| Атрибут | Тип даних | Обов'язковість | Опис | Додаткові обмеження |
|---------|-----------|----------------|------|---------------------|
| weight_entry_id | INT / BIGINT | YES | Унікальний ідентифікатор запису | PRIMARY KEY, AUTO_INCREMENT |
| user_id | INT / BIGINT | YES | Ідентифікатор користувача | FOREIGN KEY (users.user_id), INDEX |
| date | DATE | YES | Дата вимірювання | INDEX |
| weight | DECIMAL(5,2) | YES | Вага в кілограмах | CHECK (weight >= 30 AND weight <= 300) |
| bmi | DECIMAL(4,2) | YES | Розрахований BMI | - |
| notes | TEXT | NO | Нотатки користувача | - |
| created_at | TIMESTAMP | YES | Дата створення запису | DEFAULT CURRENT_TIMESTAMP |

**Індекси:**
- UNIQUE INDEX (user_id, date) - один запис на день для користувача

---

## 7. UserSessions (Сесії користувачів)

**Опис:** Таблиця для зберігання активних сесій користувачів (JWT токени).

| Атрибут | Тип даних | Обов'язковість | Опис | Додаткові обмеження |
|---------|-----------|----------------|------|---------------------|
| session_id | INT / BIGINT | YES | Унікальний ідентифікатор сесії | PRIMARY KEY, AUTO_INCREMENT |
| user_id | INT / BIGINT | YES | Ідентифікатор користувача | FOREIGN KEY (users.user_id), INDEX |
| access_token_hash | VARCHAR(255) | YES | Хеш access токену | UNIQUE |
| refresh_token_hash | VARCHAR(255) | YES | Хеш refresh токену | UNIQUE |
| device_info | VARCHAR(500) | NO | Інформація про пристрій | - |
| ip_address | VARCHAR(45) | NO | IP адреса | - |
| is_active | BOOLEAN | YES | Чи активна сесія | DEFAULT TRUE |
| created_at | TIMESTAMP | YES | Час створення сесії | DEFAULT CURRENT_TIMESTAMP |
| access_token_expires_at | TIMESTAMP | YES | Час закінчення access токену | - |
| refresh_token_expires_at | TIMESTAMP | YES | Час закінчення refresh токену | - |
| last_activity | TIMESTAMP | YES | Час останньої активності | DEFAULT CURRENT_TIMESTAMP |

---

## 8. PasswordResetTokens (Токени відновлення паролю)

**Опис:** Таблиця для зберігання токенів відновлення паролю.

| Атрибут | Тип даних | Обов'язковість | Опис | Додаткові обмеження |
|---------|-----------|----------------|------|---------------------|
| token_id | INT / BIGINT | YES | Унікальний ідентифікатор токену | PRIMARY KEY, AUTO_INCREMENT |
| user_id | INT / BIGINT | YES | Ідентифікатор користувача | FOREIGN KEY (users.user_id), INDEX |
| token_code | VARCHAR(6) | YES | 6-значний код підтвердження | INDEX |
| is_used | BOOLEAN | YES | Чи використаний токен | DEFAULT FALSE |
| attempts | INT | YES | Кількість спроб введення | DEFAULT 0 |
| created_at | TIMESTAMP | YES | Час створення токену | DEFAULT CURRENT_TIMESTAMP |
| expires_at | TIMESTAMP | YES | Час закінчення дії токену | - |

**Індекси:**
- INDEX (token_code, is_used) - для швидкої перевірки токену

---

## 9. UserSettings (Налаштування користувача)

**Опис:** Таблиця для зберігання персональних налаштувань додатку.

| Атрибут | Тип даних | Обов'язковість | Опис | Додаткові обмеження |
|---------|-----------|----------------|------|---------------------|
| settings_id | INT / BIGINT | YES | Унікальний ідентифікатор налаштувань | PRIMARY KEY, AUTO_INCREMENT |
| user_id | INT / BIGINT | YES | Ідентифікатор користувача | FOREIGN KEY (users.user_id), UNIQUE |
| measurement_system | ENUM('METRIC', 'IMPERIAL') | YES | Система вимірювання | DEFAULT 'METRIC' |
| language | VARCHAR(10) | YES | Мова інтерфейсу | DEFAULT 'uk' |
| theme | ENUM('LIGHT', 'DARK', 'AUTO') | YES | Тема оформлення | DEFAULT 'LIGHT' |
| reminder_food_enabled | BOOLEAN | YES | Нагадування про додавання їжі | DEFAULT FALSE |
| reminder_water_enabled | BOOLEAN | YES | Нагадування про воду | DEFAULT FALSE |
| weekly_reports_enabled | BOOLEAN | YES | Щотижневі звіти | DEFAULT TRUE |
| reminder_time | TIME | NO | Час нагадувань | - |
| created_at | TIMESTAMP | YES | Дата створення | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | YES | Дата оновлення | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

---

## 10. ActivityLog (Логи активності)

**Опис:** Таблиця для зберігання логів дій користувачів та адміністраторів.

| Атрибут | Тип даних | Обов'язковість | Опис | Додаткові обмеження |
|---------|-----------|----------------|------|---------------------|
| log_id | INT / BIGINT | YES | Унікальний ідентифікатор логу | PRIMARY KEY, AUTO_INCREMENT |
| user_id | INT / BIGINT | NO | Ідентифікатор користувача | FOREIGN KEY (users.user_id), INDEX |
| action_type | VARCHAR(100) | YES | Тип дії | INDEX |
| description | TEXT | NO | Опис дії | - |
| ip_address | VARCHAR(45) | NO | IP адреса | - |
| status | ENUM('SUCCESS', 'FAILURE', 'WARNING') | YES | Статус дії | DEFAULT 'SUCCESS' |
| created_at | TIMESTAMP | YES | Час дії | DEFAULT CURRENT_TIMESTAMP, INDEX |

**Типи дій:**
- LOGIN_SUCCESS, LOGIN_FAILURE
- LOGOUT
- REGISTER
- PASSWORD_RESET
- PROFILE_UPDATE
- FOOD_ADDED, FOOD_DELETED, FOOD_UPDATED
- ADMIN_ACCESS
- DATA_EXPORT

---

## 11. Recipes (Рецепти) - Priority: COULD

**Опис:** Таблиця для зберігання користувацьких рецептів.

| Атрибут | Тип даних | Обов'язковість | Опис | Додаткові обмеження |
|---------|-----------|----------------|------|---------------------|
| recipe_id | INT / BIGINT | YES | Унікальний ідентифікатор рецепту | PRIMARY KEY, AUTO_INCREMENT |
| user_id | INT / BIGINT | YES | Ідентифікатор користувача-автора | FOREIGN KEY (users.user_id) |
| name | VARCHAR(255) | YES | Назва рецепту | - |
| description | TEXT | NO | Опис рецепту | - |
| servings | INT | YES | Кількість порцій | CHECK (servings > 0) |
| total_calories | DECIMAL(7,2) | YES | Загальні калорії | - |
| total_protein | DECIMAL(6,2) | YES | Загальні білки | - |
| total_fat | DECIMAL(6,2) | YES | Загальні жири | - |
| total_carbs | DECIMAL(6,2) | YES | Загальні вуглеводи | - |
| is_public | BOOLEAN | YES | Чи публічний рецепт | DEFAULT FALSE |
| created_at | TIMESTAMP | YES | Дата створення | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | YES | Дата оновлення | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

---

## 12. RecipeIngredients (Інгредієнти рецептів) - Priority: COULD

**Опис:** Таблиця для зв'язку рецептів з продуктами.

| Атрибут | Тип даних | Обов'язковість | Опис | Додаткові обмеження |
|---------|-----------|----------------|------|---------------------|
| ingredient_id | INT / BIGINT | YES | Унікальний ідентифікатор інгредієнту | PRIMARY KEY, AUTO_INCREMENT |
| recipe_id | INT / BIGINT | YES | Ідентифікатор рецепту | FOREIGN KEY (recipes.recipe_id) |
| product_id | INT / BIGINT | YES | Ідентифікатор продукту | FOREIGN KEY (products.product_id) |
| weight_grams | DECIMAL(7,2) | YES | Вага інгредієнту в грамах | CHECK (weight_grams > 0) |
| order_index | INT | YES | Порядок інгредієнта | - |

**Індекси:**
- INDEX (recipe_id) - для швидкого отримання всіх інгредієнтів рецепту

---

## 13. DailySummary (Щоденні підсумки)

**Опис:** Агрегована таблиця для швидкого доступу до підсумків дня.

| Атрибут | Тип даних | Обов'язковість | Опис | Додаткові обмеження |
|---------|-----------|----------------|------|---------------------|
| summary_id | INT / BIGINT | YES | Унікальний ідентифікатор підсумку | PRIMARY KEY, AUTO_INCREMENT |
| user_id | INT / BIGINT | YES | Ідентифікатор користувача | FOREIGN KEY (users.user_id), INDEX |
| date | DATE | YES | Дата | INDEX |
| total_calories | DECIMAL(7,2) | YES | Загальні калорії за день | DEFAULT 0 |
| total_protein | DECIMAL(6,2) | YES | Загальні білки за день | DEFAULT 0 |
| total_fat | DECIMAL(6,2) | YES | Загальні жири за день | DEFAULT 0 |
| total_carbs | DECIMAL(6,2) | YES | Загальні вуглеводи за день | DEFAULT 0 |
| goal_achieved | BOOLEAN | YES | Чи досягнута ціль | DEFAULT FALSE |
| goal_percentage | DECIMAL(5,2) | YES | Відсоток досягнення цілі | DEFAULT 0 |
| breakfast_calories | DECIMAL(7,2) | YES | Калорії на сніданок | DEFAULT 0 |
| lunch_calories | DECIMAL(7,2) | YES | Калорії на обід | DEFAULT 0 |
| dinner_calories | DECIMAL(7,2) | YES | Калорії на вечерю | DEFAULT 0 |
| snack_calories | DECIMAL(7,2) | YES | Калорії на перекуси | DEFAULT 0 |
| updated_at | TIMESTAMP | YES | Час останнього оновлення | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

**Індекси:**
- UNIQUE INDEX (user_id, date) - один підсумок на день

---

# Ключові зв'язки між таблицями

## Зв'язок 1:1 (One-to-One)

### Users ↔ UserSettings
- **Тип:** 1:1
- **Опис:** Кожен користувач має один набір налаштувань
- **FK:** UserSettings.user_id → Users.user_id
- **Каскадність:** ON DELETE CASCADE (при видаленні користувача видаляються налаштування)

### Users ↔ UserGoals
- **Тип:** 1:1 (активна ціль)
- **Опис:** Кожен користувач має одну активну ціль
- **FK:** UserGoals.user_id → Users.user_id
- **Каскадність:** ON DELETE CASCADE
- **Примітка:** Історичні цілі зберігаються з is_active = FALSE

---

## Зв'язок 1:N (One-to-Many)

### Users → FoodDiary
- **Тип:** 1:N
- **Опис:** Один користувач може мати багато записів у щоденнику харчування
- **FK:** FoodDiary.user_id → Users.user_id
- **Каскадність:** ON DELETE CASCADE
- **Бізнес-правило:** Користувач може додавати необмежену кількість записів

### Users → WeightHistory
- **Тип:** 1:N
- **Опис:** Один користувач може мати багато записів про вагу
- **FK:** WeightHistory.user_id → Users.user_id
- **Каскадність:** ON DELETE CASCADE
- **Обмеження:** Один запис на день (UNIQUE INDEX на user_id, date)

### Users → UserSessions
- **Тип:** 1:N
- **Опис:** Один користувач може мати кілька активних сесій (різні пристрої)
- **FK:** UserSessions.user_id → Users.user_id
- **Каскадність:** ON DELETE CASCADE

### Users → PasswordResetTokens
- **Тип:** 1:N
- **Опис:** Користувач може запитувати відновлення паролю кілька разів
- **FK:** PasswordResetTokens.user_id → Users.user_id
- **Каскадність:** ON DELETE CASCADE
- **Обмеження:** Максимум 3 активних токени одночасно

### Users → Products
- **Тип:** 1:N
- **Опис:** Користувач може створити багато власних продуктів
- **FK:** Products.created_by_user_id → Users.user_id
- **Каскадність:** ON DELETE SET NULL
- **Примітка:** Глобальні продукти (is_global = TRUE) не мають автора

### Users → Recipes (Priority: COULD)
- **Тип:** 1:N
- **Опис:** Користувач може створити багато рецептів
- **FK:** Recipes.user_id → Users.user_id
- **Каскадність:** ON DELETE CASCADE

### Users → ActivityLog
- **Тип:** 1:N
- **Опис:** Кожна дія користувача записується в лог
- **FK:** ActivityLog.user_id → Users.user_id
- **Каскадність:** ON DELETE SET NULL (зберігаємо історію навіть після видалення користувача)

### Users → DailySummary
- **Тип:** 1:N
- **Опис:** Користувач має багато щоденних підсумків
- **FK:** DailySummary.user_id → Users.user_id
- **Каскадність:** ON DELETE CASCADE

### Products → FoodDiary
- **Тип:** 1:N
- **Опис:** Один продукт може використовуватися в багатьох записах щоденника
- **FK:** FoodDiary.product_id → Products.product_id
- **Каскадність:** ON DELETE RESTRICT (не можна видалити продукт, якщо є записи)

### MealTypes → FoodDiary
- **Тип:** 1:N
- **Опис:** Один тип прийому їжі може мати багато записів
- **FK:** FoodDiary.meal_type_id → MealTypes.meal_type_id
- **Каскадність:** ON DELETE RESTRICT

### Recipes → RecipeIngredients (Priority: COULD)
- **Тип:** 1:N
- **Опис:** Один рецепт має багато інгредієнтів
- **FK:** RecipeIngredients.recipe_id → Recipes.recipe_id
- **Каскадність:** ON DELETE CASCADE

### Products → RecipeIngredients (Priority: COULD)
- **Тип:** 1:N
- **Опис:** Один продукт може бути інгредієнтом багатьох рецептів
- **FK:** RecipeIngredients.product_id → Products.product_id
- **Каскадність:** ON DELETE RESTRICT

---

## Зв'язок N:M (Many-to-Many)

### Users ↔ Products (через FoodDiary)
- **Тип:** N:M
- **Опис:** Багато користувачів можуть споживати багато продуктів
- **Проміжна таблиця:** FoodDiary
- **Реалізація:** 
  - FoodDiary.user_id → Users.user_id
  - FoodDiary.product_id → Products.product_id
- **Бізнес-значення:** Відстеження споживання продуктів користувачами

### Recipes ↔ Products (через RecipeIngredients) - Priority: COULD
- **Тип:** N:M
- **Опис:** Багато рецептів можуть використовувати багато продуктів
- **Проміжна таблиця:** RecipeIngredients
- **Реалізація:**
  - RecipeIngredients.recipe_id → Recipes.recipe_id
  - RecipeIngredients.product_id → Products.product_id
- **Бізнес-значення:** Складання рецептів із продуктів

---

## Додаткові індекси для оптимізації

```sql
-- Швидкий пошук записів користувача за період
CREATE INDEX idx_food_diary_user_date ON FoodDiary (user_id, date);

-- Пошук продуктів за назвою
CREATE INDEX idx_products_name ON Products (name);

-- Фільтрація продуктів за категорією
CREATE INDEX idx_products_category ON Products (category);

-- Пошук активних сесій користувача
CREATE INDEX idx_sessions_user_active ON UserSessions (user_id, is_active);

-- Історія ваги користувача
CREATE INDEX idx_weight_history_user_date ON WeightHistory (user_id, date DESC);

-- Аналітика по датах
CREATE INDEX idx_daily_summary_date ON DailySummary (date);

-- Логи за типом дії та часом
CREATE INDEX idx_activity_log_type_time ON ActivityLog (action_type, created_at DESC);
```

---