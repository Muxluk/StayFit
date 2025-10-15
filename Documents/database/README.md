# StayFit DataBase

**Консольний застосунок (.NET 8)** для наповнення та управління тестовою базою даних **PostgreSQL** фітнес-додатка.  
Генерує реалістичні тестові дані за допомогою бібліотеки **Bogus** (українська локалізація) та дозволяє переглядати таблиці у форматованому вигляді.

---

##  Основні можливості

-  **Перегляд даних:**  
  Вивід до **50 записів** з кожної таблиці у форматованому вигляді.  
  Якщо таблиця порожня — виводиться `No data found`.

-  **Генерація тестових даних:**  
  Створення **10–30 користувачів**, продуктів, щоденникових записів та пов’язаних об’єктів в одній транзакції.

-  **Інтерактивне меню:**  
  Простий текстовий інтерфейс у консолі.

---

##  Технічні вимоги

- **.NET 8.0 SDK** або новіший  
- **PostgreSQL 12** або новіший  
- Підтримувані системи: **Windows / macOS / Linux**

---

##  Файли проекту

| Файл | Опис |
|------|------|
| `Program.cs` | Головний файл застосунку з рядком підключення |
| `DatabaseConsoleApp.csproj` | Файл проєкту (.NET) |
| `schema.sql` | SQL-скрипт для створення таблиць і обмежень |
| `README.md` | Поточний файл з інструкціями |

---

##  Встановлення та запуск

### 1. Встановіть .NET 8 SDK

Перевірте встановлення:

===bash===

dotnet --version
### 2. Встановіть PostgreSQL

Завантажте з офіційного сайту та встановіть.

### 3. Створіть базу даних
   
CREATE DATABASE stayfit;

### 4. Застосуйте схему
psql -U postgres -d fitness_db -f schema.sql

або виконайте schema.sql через pgAdmin.

### 5. Налаштуйте проєкт

Створіть директорію і помістіть файли:

===bash===

mkdir DatabaseConsoleApp

cd DatabaseConsoleApp

Скопіюйте Program.cs, DatabaseConsoleApp.csproj, schema.sql


У файлі Program.cs змініть рядок підключення:

private const string ConnectionString =
    "Host=localhost;Port=5432;Database=fitness_db;Username=postgres;Password=your_password";

### 6. Встановіть залежності та зберіть проект

===bash===
   
dotnet restore

dotnet build

### 7. Запустіть застосунок

===bash===
   
dotnet run

Меню програми
================================           Main Menu            ================================
1. Display data from all tables
2. Generate test data
3. Exit
Your choice:


1 → Перегляд даних з усіх таблиць

2 → Генерація тестових даних

3 → Вихід

Опцію генерації можна виконувати кілька разів — дані додаються.

 Процес генерації даних

Використовується Bogus (локаль uk) для створення імен, адрес, описів тощо.

Паролі хешуються за допомогою BCrypt.Net-Next.

Обсяг даних: 10–30 користувачів, продуктів, записів тощо.

Тривалість процесу: 10–30 секунд.

## Налаштування

Рядок підключення (у Program.cs або змінній середовища):

Host=localhost;Port=5432;Database=fitness_db;Username=postgres;Password=your_password

# Файл schema.sql (огляд)

Має створювати основні таблиці, наприклад:

users, products, diary_entries, workouts, product_categories

та визначати PRIMARY KEY, FOREIGN KEY, UNIQUE обмеження.

## Вирішення поширених проблем
### 1.  Проблеми з підключенням до PostgreSQL

Перевірте, чи запущений сервіс:

Windows: services.msc

Linux: sudo systemctl status postgresql

Перевірте порт 5432.

Перевірте підключення:

psql -U postgres -d fitness_db

### 2.  Помилки схеми або вставки
psql -U postgres -c "DROP DATABASE IF EXISTS fitness_db;"

psql -U postgres -c "CREATE DATABASE fitness_db;"

psql -U postgres -d fitness_db -f schema.sql

### 3.  Помилки збірки / NuGet
dotnet nuget locals all --clear

dotnet restore

dotnet build
