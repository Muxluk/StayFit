using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Bogus;
using Npgsql;
using BCrypt.Net;

namespace DatabaseConsoleApp
{
    class Program
    {
        private const string ConnectionString = "Host=localhost;Port=5432;Database=StayFit;Username=postgres;Password=your_password";

        static async Task Main(string[] args)
        {
            Console.OutputEncoding = Encoding.UTF8;
            Console.WriteLine("=== Fitness Database Console App ===\n");

            while (true)
            {
                DisplayMenu();
                var choice = Console.ReadLine();

                try
                {
                    switch (choice)
                    {
                        case "1":
                            await DisplayAllData();
                            break;
                        case "2":
                            await GenerateTestData();
                            break;
                        case "3":
                            Console.WriteLine("Exiting application...");
                            return;
                        case "-1":
                            await ClearAllData();
                            break;
                        default:
                            Console.WriteLine("Invalid choice. Please try again.\n");
                            break;
                    }
                }
                catch (Exception ex)
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine($"\nAn error occurred: {ex.Message}\n");
                    Console.ResetColor();
                }

                Console.WriteLine("\nPress any key to continue...");
                Console.ReadKey();
                Console.Clear();
            }
        }

        static void DisplayMenu()
        {
            Console.WriteLine("================================");
            Console.WriteLine("          Main Menu           ");
            Console.WriteLine("================================");
            Console.WriteLine("1. Display data from all tables");
            Console.WriteLine("2. Generate test data");
            Console.WriteLine("3. Exit");
            Console.Write("\nYour choice: ");
        }

        static async Task ClearAllData()
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.Write("Are you sure you want to delete ALL data from the database? This cannot be undone. (y/n): ");
            Console.ResetColor();

            string? confirmation = Console.ReadLine();
            if (confirmation?.ToLower() != "y")
            {
                Console.WriteLine("Operation canceled.");
                return;
            }

            Console.WriteLine("\nClearing all tables...");
            try
            {
                await using var conn = new NpgsqlConnection(ConnectionString);
                await conn.OpenAsync();

                string truncateCommand = @"
                    TRUNCATE
                        users, user_goals, user_settings, meal_types,
                        products, food_diary, weight_history, daily_summary,
                        user_sessions, password_reset_tokens, activity_log
                    RESTART IDENTITY CASCADE;";

                await using var cmd = new NpgsqlCommand(truncateCommand, conn);
                await cmd.ExecuteNonQueryAsync();

                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("All tables have been successfully cleared.");
                Console.ResetColor();
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"An error occurred while clearing tables: {ex.Message}");
                Console.ResetColor();
            }
        }

        static async Task DisplayAllData()
        {
            var tables = new[]
            {
                "users", "user_goals", "user_settings", "meal_types",
                "products", "food_diary", "weight_history", "daily_summary",
                "user_sessions", "password_reset_tokens", "activity_log"
            };

            await using var conn = new NpgsqlConnection(ConnectionString);
            await conn.OpenAsync();

            foreach (var table in tables)
            {
                Console.WriteLine($"\n=== Table: {table.ToUpper()} ===");
                await DisplayTableData(conn, table);
            }
        }

        static async Task DisplayTableData(NpgsqlConnection conn, string tableName)
        {
            try
            {
                var query = $"SELECT * FROM \"{tableName}\" LIMIT 50";
                await using var cmd = new NpgsqlCommand(query, conn);
                await using var reader = await cmd.ExecuteReaderAsync();

                if (!reader.HasRows)
                {
                    Console.WriteLine("No data found.\n");
                    return;
                }

                var columns = new List<string>();
                for (int i = 0; i < reader.FieldCount; i++)
                {
                    columns.Add(reader.GetName(i));
                }

                Console.WriteLine(string.Join(" | ", columns.Select(c => c.PadRight(15).Substring(0, 15))));
                Console.WriteLine(new string('-', columns.Count * 18));

                int rowCount = 0;
                while (await reader.ReadAsync())
                {
                    var values = new List<string>();
                    for (int i = 0; i < reader.FieldCount; i++)
                    {
                        var value = reader.IsDBNull(i) ? "NULL" : reader.GetValue(i).ToString();
                        var displayValue = value?.Length > 15 ? value.Substring(0, 12) + "..." : (value ?? "");
                        values.Add(displayValue.PadRight(15));
                    }
                    Console.WriteLine(string.Join(" | ", values));
                    rowCount++;
                }

                Console.WriteLine($"\nDisplayed records: {rowCount}\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error reading table {tableName}: {ex.Message}\n");
            }
        }

        static async Task GenerateTestData()
        {
            Console.WriteLine("\nStarting test data generation...\n");

            await using var conn = new NpgsqlConnection(ConnectionString);
            await conn.OpenAsync();
            await using var transaction = await conn.BeginTransactionAsync();

            try
            {
                Randomizer.Seed = new Random();
                var userCount = new Random().Next(10, 20);

                Console.WriteLine($"Generating {userCount} users...");
                var userIds = await GenerateUsers(conn, transaction, userCount);
                Console.WriteLine($"-> {userIds.Count} users inserted.");

                Console.WriteLine("Generating meal types...");
                var mealTypeIds = await GenerateMealTypes(conn, transaction);
                Console.WriteLine($"-> {mealTypeIds.Count} meal types inserted.");

                Console.WriteLine("Generating products...");
                var productIds = await GenerateProducts(conn, transaction, userIds);
                Console.WriteLine($"-> {productIds.Count} products inserted.");

                Console.WriteLine("Generating user goals...");
                var goalCount = await GenerateUserGoals(conn, transaction, userIds);
                Console.WriteLine($"-> {goalCount} user goals inserted.");

                Console.WriteLine("Generating user settings...");
                var settingsCount = await GenerateUserSettings(conn, transaction, userIds);
                Console.WriteLine($"-> {settingsCount} user settings inserted.");

                Console.WriteLine("Generating food diary entries...");
                var diaryCount = await GenerateFoodDiary(conn, transaction, userIds, productIds, mealTypeIds);
                Console.WriteLine($"-> {diaryCount} food diary entries inserted.");

                Console.WriteLine("Generating weight history...");
                var weightCount = await GenerateWeightHistory(conn, transaction, userIds);
                Console.WriteLine($"-> {weightCount} weight history entries inserted.");

                Console.WriteLine("Generating daily summaries...");
                var summaryCount = await GenerateDailySummary(conn, transaction, userIds);
                Console.WriteLine($"-> {summaryCount} daily summaries inserted.");

                Console.WriteLine("Generating user sessions...");
                var sessionCount = await GenerateUserSessions(conn, transaction, userIds);
                Console.WriteLine($"-> {sessionCount} user sessions inserted.");

                Console.WriteLine("Generating activity logs...");
                var logCount = await GenerateActivityLog(conn, transaction, userIds);
                Console.WriteLine($"-> {logCount} activity log entries inserted.");

                await transaction.CommitAsync();
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("\nTest data generation completed successfully!");
                Console.ResetColor();
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"\nError during data generation: {ex.Message}");
                Console.WriteLine("Transaction rolled back.");
                Console.ResetColor();
                throw;
            }
        }

        static async Task<List<int>> GenerateUsers(NpgsqlConnection conn, NpgsqlTransaction transaction, int count)
        {
            var userIds = new List<int>();
            var faker = new Faker("uk");
            var activityLevels = new[] { "SEDENTARY", "LIGHTLY_ACTIVE", "MODERATELY_ACTIVE", "VERY_ACTIVE", "EXTRA_ACTIVE" };
            var genders = new[] { "MALE", "FEMALE" };

            var maleFirstNames = new[] { "Andrii", "Serhii", "Maksym", "Volodymyr", "Yurii", "Ivan", "Roman", "Artem", "Bohdan", "Taras", "John", "Michael", "David", "Chris", "James", "Robert", "Daniel", "William", "Thomas", "Richard" };
            var femaleFirstNames = new[] { "Olena", "Maria", "Nataliia", "Tetiana", "Anna", "Iryna", "Kateryna", "Yuliia", "Svitlana", "Viktoriia", "Jessica", "Emily", "Sarah", "Jennifer", "Elizabeth", "Linda", "Patricia", "Susan", "Ashley", "Mary" };
            var lastNames = new[] { "Kovalenko", "Shevchenko", "Boiko", "Tkachenko", "Kravchenko", "Melnyk", "Petrenko", "Ivanenko", "Kovalchuk", "Ponomarenko", "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez" };

            for (int i = 0; i < count; i++)
            {
                var gender = faker.PickRandom(genders);
                var firstName = gender == "MALE" ? faker.PickRandom(maleFirstNames) : faker.PickRandom(femaleFirstNames);
                var lastName = faker.PickRandom(lastNames);
                var dateOfBirth = faker.Date.Between(DateTime.Now.AddYears(-60), DateTime.Now.AddYears(-13));
                var height = Math.Round((decimal)faker.Random.Double(150, 200), 2);
                var currentWeight = Math.Round((decimal)faker.Random.Double(50, 120), 2);
                var targetWeight = faker.Random.Bool(0.7f) ? Math.Round((decimal)faker.Random.Double(50, 120), 2) : (decimal?)null;

                if (targetWeight.HasValue && targetWeight.Value == currentWeight)
                {
                    targetWeight = currentWeight + 1.5m;
                }

                var query = @"
                    INSERT INTO users (email, password_hash, first_name, last_name, date_of_birth, gender, height, current_weight, target_weight, activity_level, role)
                    VALUES (@email, @password_hash, @first_name, @last_name, @date_of_birth, @gender, @height, @current_weight, @target_weight, @activity_level, @role)
                    RETURNING user_id";

                await using var cmd = new NpgsqlCommand(query, conn, transaction);

                var uniqueSuffix = faker.Random.Replace("#####");
                var tempEmail = faker.Internet.Email(firstName, lastName).Split('@');
                var uniqueEmail = $"{tempEmail[0]}{uniqueSuffix}@{tempEmail[1]}";
                cmd.Parameters.AddWithValue("email", uniqueEmail);

                cmd.Parameters.AddWithValue("password_hash", BCrypt.Net.BCrypt.HashPassword("password123"));

                cmd.Parameters.AddWithValue("first_name", firstName);
                cmd.Parameters.AddWithValue("last_name", lastName);
                cmd.Parameters.AddWithValue("date_of_birth", dateOfBirth);
                cmd.Parameters.AddWithValue("gender", gender);
                cmd.Parameters.AddWithValue("height", height);
                cmd.Parameters.AddWithValue("current_weight", currentWeight);
                cmd.Parameters.AddWithValue("target_weight", targetWeight.HasValue ? targetWeight.Value : DBNull.Value);
                cmd.Parameters.AddWithValue("activity_level", faker.PickRandom(activityLevels));
                cmd.Parameters.AddWithValue("role", i == 0 ? "ADMIN" : "USER");

                var result = await cmd.ExecuteScalarAsync();
                if (result != null)
                {
                    userIds.Add((int)result);
                }
            }

            return userIds;
        }

        static async Task<List<int>> GenerateMealTypes(NpgsqlConnection conn, NpgsqlTransaction transaction)
        {
            var mealTypeIds = new List<int>();
            var mealTypes = new[] { ("BREAKFAST", 1), ("LUNCH", 2), ("DINNER", 3), ("SNACK", 4) };
            var selectQuery = "SELECT meal_type_id FROM meal_types WHERE name = @name";

            foreach (var (name, order) in mealTypes)
            {
                var insertQuery = @"
                    INSERT INTO meal_types (name, display_order)
                    VALUES (@name, @display_order)
                    ON CONFLICT (name) DO NOTHING";

                await using (var insertCmd = new NpgsqlCommand(insertQuery, conn, transaction))
                {
                    insertCmd.Parameters.AddWithValue("name", name);
                    insertCmd.Parameters.AddWithValue("display_order", order);
                    await insertCmd.ExecuteNonQueryAsync();
                }

                await using (var selectCmd = new NpgsqlCommand(selectQuery, conn, transaction))
                {
                    selectCmd.Parameters.AddWithValue("name", name);
                    var mealId = await selectCmd.ExecuteScalarAsync();
                    if (mealId != null) mealTypeIds.Add((int)mealId);
                }
            }
            return mealTypeIds;
        }

        static async Task<List<int>> GenerateProducts(NpgsqlConnection conn, NpgsqlTransaction transaction, List<int> userIds)
        {
            var productIds = new List<int>();
            var faker = new Faker("uk");
            var categories = new[] { "VEGETABLES", "FRUITS", "MEAT", "FISH", "DAIRY", "GRAINS", "SNACKS", "BEVERAGES", "OTHER" };

            var productNames = new Dictionary<string, (decimal cal, decimal prot, decimal fat, decimal carb)>
            {
                { "Chicken Breast", (165, 31, 3.6m, 0) }, { "Brown Rice", (370, 7.9m, 2.9m, 77.2m) },
                { "Broccoli", (34, 2.8m, 0.4m, 7) }, { "Salmon", (208, 20, 13, 0) },
                { "Greek Yogurt", (59, 10, 0.4m, 3.6m) }, { "Apple", (52, 0.3m, 0.2m, 14) },
                { "Banana", (89, 1.1m, 0.3m, 23) }, { "Eggs", (155, 13, 11, 1.1m) },
                { "Oatmeal", (389, 16.9m, 6.9m, 66.3m) }, { "Almonds", (579, 21.2m, 49.9m, 21.6m) }
            };

            foreach (var product in productNames)
            {
                var query = @"
                    INSERT INTO products (name, category, calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g, is_global, created_by_user_id)
                    VALUES (@name, @category, @calories, @protein, @fat, @carbs, @is_global, @created_by)
                    RETURNING product_id";

                await using var cmd = new NpgsqlCommand(query, conn, transaction);
                cmd.Parameters.AddWithValue("name", product.Key);
                cmd.Parameters.AddWithValue("category", faker.PickRandom(categories));
                cmd.Parameters.AddWithValue("calories", product.Value.cal);
                cmd.Parameters.AddWithValue("protein", product.Value.prot);
                cmd.Parameters.AddWithValue("fat", product.Value.fat);
                cmd.Parameters.AddWithValue("carbs", product.Value.carb);
                cmd.Parameters.AddWithValue("is_global", true);
                cmd.Parameters.AddWithValue("created_by", DBNull.Value);
                var result = await cmd.ExecuteScalarAsync();
                if (result != null) productIds.Add((int)result);
            }

            for (int i = 0; i < 20; i++)
            {
                var query = @"
                    INSERT INTO products (name, category, calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g, is_global, created_by_user_id)
                    VALUES (@name, @category, @calories, @protein, @fat, @carbs, @is_global, @created_by)
                    RETURNING product_id";

                await using var cmd = new NpgsqlCommand(query, conn, transaction);
                cmd.Parameters.AddWithValue("name", $"Custom Product {i + 1}");
                cmd.Parameters.AddWithValue("category", faker.PickRandom(categories));
                cmd.Parameters.AddWithValue("calories", Math.Round((decimal)faker.Random.Double(20, 600), 2));
                cmd.Parameters.AddWithValue("protein", Math.Round((decimal)faker.Random.Double(0, 50), 2));
                cmd.Parameters.AddWithValue("fat", Math.Round((decimal)faker.Random.Double(0, 40), 2));
                cmd.Parameters.AddWithValue("carbs", Math.Round((decimal)faker.Random.Double(0, 80), 2));
                cmd.Parameters.AddWithValue("is_global", false);
                cmd.Parameters.AddWithValue("created_by", faker.PickRandom(userIds));
                var result = await cmd.ExecuteScalarAsync();
                if (result != null) productIds.Add((int)result);
            }
            return productIds;
        }

        static async Task<int> GenerateUserGoals(NpgsqlConnection conn, NpgsqlTransaction transaction, List<int> userIds)
        {
            var faker = new Faker();
            var goalTypes = new[] { "WEIGHT_LOSS", "WEIGHT_GAIN", "MAINTENANCE" };
            int count = 0;
            foreach (var userId in userIds)
            {
                var query = @"
                    INSERT INTO user_goals (user_id, daily_calories, goal_type, protein_grams, fat_grams, carbs_grams, is_active)
                    VALUES (@user_id, @daily_calories, @goal_type, @protein, @fat, @carbs, @is_active)";
                await using var cmd = new NpgsqlCommand(query, conn, transaction);
                cmd.Parameters.AddWithValue("user_id", userId);
                cmd.Parameters.AddWithValue("daily_calories", Math.Round((decimal)faker.Random.Double(1500, 3000), 2));
                cmd.Parameters.AddWithValue("goal_type", faker.PickRandom(goalTypes));
                cmd.Parameters.AddWithValue("protein", Math.Round((decimal)faker.Random.Double(80, 200), 2));
                cmd.Parameters.AddWithValue("fat", Math.Round((decimal)faker.Random.Double(40, 100), 2));
                cmd.Parameters.AddWithValue("carbs", Math.Round((decimal)faker.Random.Double(150, 400), 2));
                cmd.Parameters.AddWithValue("is_active", true);
                await cmd.ExecuteNonQueryAsync();
                count++;
            }
            return count;
        }

        static async Task<int> GenerateUserSettings(NpgsqlConnection conn, NpgsqlTransaction transaction, List<int> userIds)
        {
            var faker = new Faker();
            var languages = new[] { "uk", "en", "ru" };
            var themes = new[] { "LIGHT", "DARK", "AUTO" };
            int count = 0;
            foreach (var userId in userIds)
            {
                var query = @"
                    INSERT INTO user_settings (user_id, language, theme, reminder_food_enabled, weekly_reports_enabled)
                    VALUES (@user_id, @language, @theme, @reminder_food, @weekly_reports)";
                await using var cmd = new NpgsqlCommand(query, conn, transaction);
                cmd.Parameters.AddWithValue("user_id", userId);
                cmd.Parameters.AddWithValue("language", faker.PickRandom(languages));
                cmd.Parameters.AddWithValue("theme", faker.PickRandom(themes));
                cmd.Parameters.AddWithValue("reminder_food", faker.Random.Bool());
                cmd.Parameters.AddWithValue("weekly_reports", faker.Random.Bool(0.8f));
                await cmd.ExecuteNonQueryAsync();
                count++;
            }
            return count;
        }

        static async Task<int> GenerateFoodDiary(NpgsqlConnection conn, NpgsqlTransaction transaction, List<int> userIds, List<int> productIds, List<int> mealTypeIds)
        {
            var faker = new Faker();
            int count = 0;
            if (!productIds.Any() || !mealTypeIds.Any()) return 0;

            foreach (var userId in userIds)
            {
                var entriesCount = faker.Random.Int(5, 15);
                for (int i = 0; i < entriesCount; i++)
                {
                    var date = faker.Date.Between(DateTime.Now.AddDays(-30), DateTime.Now);
                    var time = faker.Date.Between(date.Date.AddHours(6), date.Date.AddHours(22)).TimeOfDay;
                    var weightGrams = Math.Round((decimal)faker.Random.Double(50, 500), 2);
                    var calories = Math.Round((decimal)faker.Random.Double(50, 800), 2);
                    var protein = Math.Round((decimal)faker.Random.Double(5, 50), 2);

                    var query = @"
                        INSERT INTO food_diary (user_id, product_id, meal_type_id, date, time, weight_grams, calories, protein)
                        VALUES (@user_id, @product_id, @meal_type_id, @date, @time, @weight_grams, @calories, @protein)";
                    await using var cmd = new NpgsqlCommand(query, conn, transaction);
                    cmd.Parameters.AddWithValue("user_id", userId);
                    cmd.Parameters.AddWithValue("product_id", faker.PickRandom(productIds));
                    cmd.Parameters.AddWithValue("meal_type_id", faker.PickRandom(mealTypeIds));
                    cmd.Parameters.AddWithValue("date", date.Date);
                    cmd.Parameters.AddWithValue("time", time);
                    cmd.Parameters.AddWithValue("weight_grams", weightGrams);
                    cmd.Parameters.AddWithValue("calories", calories);
                    cmd.Parameters.AddWithValue("protein", protein);
                    await cmd.ExecuteNonQueryAsync();
                    count++;
                }
            }
            return count;
        }

        static async Task<int> GenerateWeightHistory(NpgsqlConnection conn, NpgsqlTransaction transaction, List<int> userIds)
        {
            var faker = new Faker();
            int count = 0;
            foreach (var userId in userIds)
            {
                var entriesCount = faker.Random.Int(5, 10);
                var baseWeight = (decimal)faker.Random.Double(55, 110);
                for (int i = 0; i < entriesCount; i++)
                {
                    var date = DateTime.Now.AddDays(-entriesCount + i);
                    var weight = Math.Round(baseWeight + (decimal)faker.Random.Double(-2, 2), 2);
                    var height = (decimal)faker.Random.Double(160, 190);
                    var bmi = Math.Round(weight / ((height / 100) * (height / 100)), 2);

                    var query = @"
                        INSERT INTO weight_history (user_id, date, weight, bmi)
                        VALUES (@user_id, @date, @weight, @bmi)
                        ON CONFLICT (user_id, date) DO NOTHING";
                    await using var cmd = new NpgsqlCommand(query, conn, transaction);
                    cmd.Parameters.AddWithValue("user_id", userId);
                    cmd.Parameters.AddWithValue("date", date.Date);
                    cmd.Parameters.AddWithValue("weight", weight);
                    cmd.Parameters.AddWithValue("bmi", bmi);
                    await cmd.ExecuteNonQueryAsync();
                    count++;
                }
            }
            return count;
        }

        static async Task<int> GenerateDailySummary(NpgsqlConnection conn, NpgsqlTransaction transaction, List<int> userIds)
        {
            var faker = new Faker();
            int count = 0;
            foreach (var userId in userIds)
            {
                var entriesCount = faker.Random.Int(5, 10);
                for (int i = 0; i < entriesCount; i++)
                {
                    var date = DateTime.Now.AddDays(-entriesCount + i);
                    var totalCalories = Math.Round((decimal)faker.Random.Double(1200, 2800), 2);
                    var totalProtein = Math.Round((decimal)faker.Random.Double(60, 180), 2);

                    var query = @"
                        INSERT INTO daily_summary (user_id, date, total_calories, total_protein, goal_achieved, breakfast_calories, lunch_calories, dinner_calories)
                        VALUES (@user_id, @date, @total_calories, @total_protein, @goal_achieved, @breakfast_cal, @lunch_cal, @dinner_cal)
                        ON CONFLICT (user_id, date) DO NOTHING";
                    await using var cmd = new NpgsqlCommand(query, conn, transaction);
                    cmd.Parameters.AddWithValue("user_id", userId);
                    cmd.Parameters.AddWithValue("date", date.Date);
                    cmd.Parameters.AddWithValue("total_calories", totalCalories);
                    cmd.Parameters.AddWithValue("total_protein", totalProtein);
                    cmd.Parameters.AddWithValue("goal_achieved", faker.Random.Bool(0.6f));
                    cmd.Parameters.AddWithValue("breakfast_cal", Math.Round(totalCalories * 0.25m, 2));
                    cmd.Parameters.AddWithValue("lunch_cal", Math.Round(totalCalories * 0.35m, 2));
                    cmd.Parameters.AddWithValue("dinner_cal", Math.Round(totalCalories * 0.40m, 2));
                    await cmd.ExecuteNonQueryAsync();
                    count++;
                }
            }
            return count;
        }

        static async Task<int> GenerateUserSessions(NpgsqlConnection conn, NpgsqlTransaction transaction, List<int> userIds)
        {
            var faker = new Faker();
            int count = 0;
            foreach (var userId in userIds.Take(20))
            {
                var sessionsCount = faker.Random.Int(1, 3);
                for (int i = 0; i < sessionsCount; i++)
                {
                    var createdAt = faker.Date.Between(DateTime.Now.AddDays(-7), DateTime.Now);
                    var query = @"
                        INSERT INTO user_sessions (user_id, access_token_hash, refresh_token_hash, device_info, is_active, created_at, access_token_expires_at)
                        VALUES (@user_id, @access_token, @refresh_token, @device_info, @is_active, @created_at, @expires_at)";
                    await using var cmd = new NpgsqlCommand(query, conn, transaction);
                    cmd.Parameters.AddWithValue("user_id", userId);
                    cmd.Parameters.AddWithValue("access_token", BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString()));
                    cmd.Parameters.AddWithValue("refresh_token", BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString()));
                    cmd.Parameters.AddWithValue("device_info", faker.Internet.UserAgent());
                    cmd.Parameters.AddWithValue("is_active", faker.Random.Bool(0.7f));
                    cmd.Parameters.AddWithValue("created_at", createdAt);
                    cmd.Parameters.AddWithValue("expires_at", createdAt.AddHours(24));
                    await cmd.ExecuteNonQueryAsync();
                    count++;
                }
            }
            return count;
        }

        static async Task<int> GenerateActivityLog(NpgsqlConnection conn, NpgsqlTransaction transaction, List<int> userIds)
        {
            var faker = new Faker();
            var actions = new[] { "USER_LOGIN", "USER_LOGOUT", "FOOD_ADDED", "WEIGHT_UPDATED", "GOAL_UPDATED", "PROFILE_UPDATED" };
            var statuses = new[] { "SUCCESS", "SUCCESS", "SUCCESS", "FAILURE", "WARNING" };
            int count = 0;
            for (int i = 0; i < 100; i++)
            {
                var query = @"
                    INSERT INTO activity_log (user_id, action_type, description, status)
                    VALUES (@user_id, @action_type, @description, @status)";
                await using var cmd = new NpgsqlCommand(query, conn, transaction);
                cmd.Parameters.AddWithValue("user_id", faker.Random.Bool(0.9f) && userIds.Any() ? faker.PickRandom(userIds) : DBNull.Value);
                cmd.Parameters.AddWithValue("action_type", faker.PickRandom(actions));
                cmd.Parameters.AddWithValue("description", faker.Lorem.Sentence());
                cmd.Parameters.AddWithValue("status", faker.PickRandom(statuses));
                await cmd.ExecuteNonQueryAsync();
                count++;
            }
            return count;
        }
    }
}

