-- Sample Data for Students' Coding Portal
-- Insert this after running the database schema

-- Insert sample levels
INSERT INTO levels (level_number, title, description) VALUES
(1, 'C Programming Basics', 'Fundamental concepts of C programming language including variables, data types, and basic syntax.'),
(2, 'Control Structures', 'Learn about if-else statements, loops, and switch cases in C programming.'),
(3, 'Functions and Arrays', 'Understanding function definitions, parameters, and array manipulation in C.'),
(4, 'Pointers and Memory', 'Advanced concepts including pointers, memory management, and dynamic allocation.'),
(5, 'File Handling', 'Working with files, reading and writing data in C programming.');

-- Insert sample MCQs for Level 1 (C Programming Basics)
INSERT INTO mcqs (level_id, question_number, question, options, correct_answer, explanation) VALUES
(1, 1, 'What is the correct way to declare a variable in C?', 
ARRAY['int x;', 'variable x;', 'x = 5;', 'declare x;'], 
0, 'In C, variables are declared using a data type followed by the variable name and a semicolon.'),

(1, 2, 'Which of the following is a valid C data type?', 
ARRAY['string', 'int', 'boolean', 'character'], 
1, 'int is a valid C data type. C does not have a built-in string type or boolean type.'),

(1, 3, 'What is the output of printf("%d", 5/2);?', 
ARRAY['2.5', '2', '2.0', 'Error'], 
1, 'Integer division in C truncates the decimal part, so 5/2 = 2.'),

(1, 4, 'Which header file is required for printf() function?', 
ARRAY['<stdio.h>', '<stdlib.h>', '<string.h>', '<math.h>'], 
0, 'The printf() function is defined in the stdio.h header file.'),

(1, 5, 'What is the size of an int data type in C?', 
ARRAY['2 bytes', '4 bytes', 'Depends on the compiler', '8 bytes'], 
2, 'The size of int varies depending on the compiler and system architecture.'),

(1, 6, 'Which operator is used for assignment in C?', 
ARRAY['==', '=', ':=', '->'], 
1, 'The = operator is used for assignment in C.'),

(1, 7, 'What is the correct way to comment a single line in C?', 
ARRAY['// comment', '/* comment */', '# comment', '-- comment'], 
0, '// is used for single-line comments in C (C99 standard).'),

(1, 8, 'Which of the following is a valid identifier in C?', 
ARRAY['2variable', '_variable', 'variable-name', 'variable name'], 
1, 'Identifiers can start with underscore and contain letters, digits, and underscores.'),

(1, 9, 'What is the output of printf("%c", 65);?', 
ARRAY['65', 'A', 'Error', '65.0'], 
1, 'ASCII value 65 corresponds to the character A.'),

(1, 10, 'Which of the following is NOT a valid C keyword?', 
ARRAY['int', 'float', 'string', 'char'], 
2, 'string is not a keyword in C. C uses char arrays for strings.'),

(1, 11, 'What is the purpose of the #include directive?', 
ARRAY['To include comments', 'To include header files', 'To include variables', 'To include functions'], 
1, '#include is used to include header files in C programs.'),

(1, 12, 'Which of the following is a valid way to declare a constant in C?', 
ARRAY['const int x = 5;', 'constant int x = 5;', 'final int x = 5;', 'fixed int x = 5;'], 
0, 'const keyword is used to declare constants in C.'),

(1, 13, 'What is the output of printf("%d", sizeof(char));?', 
ARRAY['1', '2', '4', '8'], 
0, 'The size of char is always 1 byte in C.'),

(1, 14, 'Which of the following is a valid escape sequence?', 
ARRAY['\n', '\t', '\r', 'All of the above'], 
3, 'All of these are valid escape sequences in C.'),

(1, 15, 'What is the purpose of the main() function?', 
ARRAY['It is optional', 'It is the entry point', 'It is for comments', 'It is for variables'], 
1, 'main() is the entry point of a C program.'),

(1, 16, 'Which of the following is a valid way to declare multiple variables?', 
ARRAY['int a, b, c;', 'int a; int b; int c;', 'Both A and B', 'None of the above'], 
2, 'Both methods are valid for declaring multiple variables.'),

(1, 17, 'What is the output of printf("%d", 10 % 3);?', 
ARRAY['3', '1', '3.33', 'Error'], 
1, 'The modulo operator % returns the remainder of division.'),

(1, 18, 'Which of the following is a valid format specifier for float?', 
ARRAY['%d', '%f', '%s', '%c'], 
1, '%f is used to print float values in C.'),

(1, 19, 'What is the purpose of the return statement in main()?', 
ARRAY['It is optional', 'It indicates program success/failure', 'It is for comments', 'It is for variables'], 
1, 'return 0 indicates successful execution, non-zero indicates error.'),

(1, 20, 'Which of the following is NOT a valid arithmetic operator?', 
ARRAY['+', '-', '*', '&'], 
3, '& is a bitwise operator, not an arithmetic operator.');

-- Insert sample MCQs for Level 2 (Control Structures)
INSERT INTO mcqs (level_id, question_number, question, options, correct_answer, explanation) VALUES
(2, 1, 'Which keyword is used for conditional statements in C?', 
ARRAY['if', 'when', 'check', 'condition'], 
0, 'if is the keyword used for conditional statements in C.'),

(2, 2, 'What is the correct syntax for an if statement?', 
ARRAY['if (condition) statement;', 'if condition statement;', 'if condition: statement;', 'if condition then statement;'], 
0, 'The correct syntax is if (condition) statement;'),

(2, 3, 'Which loop is used when you know the number of iterations?', 
ARRAY['while', 'for', 'do-while', 'All of the above'], 
1, 'for loop is typically used when the number of iterations is known.'),

(2, 4, 'What is the output of: int i = 0; while(i < 3) { printf("%d", i); i++; }?', 
ARRAY['012', '123', '0123', 'Error'], 
0, 'The loop prints 0, 1, 2 and stops when i becomes 3.'),

(2, 5, 'Which statement is used to skip the current iteration of a loop?', 
ARRAY['break', 'continue', 'return', 'exit'], 
1, 'continue skips the current iteration and continues with the next one.'),

(2, 6, 'What is the purpose of the break statement?', 
ARRAY['To exit a loop', 'To skip iteration', 'To pause execution', 'To continue execution'], 
0, 'break is used to exit a loop or switch statement.'),

(2, 7, 'Which of the following is a valid switch case syntax?', 
ARRAY['switch (variable) { case 1: break; }', 'switch variable { case 1: break; }', 'switch (variable) case 1: break;', 'switch variable case 1: break;'], 
0, 'The correct syntax is switch (variable) { case 1: break; }'),

(2, 8, 'What is the difference between while and do-while loops?', 
ARRAY['No difference', 'do-while executes at least once', 'while is faster', 'do-while is deprecated'], 
1, 'do-while loop executes the body at least once before checking the condition.'),

(2, 9, 'Which operator is used for logical AND?', 
ARRAY['&&', '&', 'AND', 'and'], 
0, '&& is the logical AND operator in C.'),

(2, 10, 'What is the output of: int x = 5; if(x == 5) printf("Yes"); else printf("No");?', 
ARRAY['Yes', 'No', 'YesNo', 'Error'], 
0, 'Since x equals 5, the condition is true and "Yes" is printed.'),

(2, 11, 'Which loop is guaranteed to execute at least once?', 
ARRAY['for', 'while', 'do-while', 'None of the above'], 
2, 'do-while loop executes the body first, then checks the condition.'),

(2, 12, 'What is the purpose of the default case in a switch statement?', 
ARRAY['It is required', 'It handles unmatched cases', 'It is optional', 'It is deprecated'], 
1, 'default case handles any value that doesn''t match other cases.'),

(2, 13, 'Which operator is used for logical OR?', 
ARRAY['||', '|', 'OR', 'or'], 
0, '|| is the logical OR operator in C.'),

(2, 14, 'What is the output of: for(int i = 0; i < 3; i++) printf("%d", i);?', 
ARRAY['012', '123', '0123', 'Error'], 
0, 'The for loop prints 0, 1, 2 and stops when i becomes 3.'),

(2, 15, 'Which statement is used to exit a function?', 
ARRAY['break', 'continue', 'return', 'exit'], 
2, 'return is used to exit a function and optionally return a value.'),

(2, 16, 'What is the purpose of the else statement?', 
ARRAY['It is required', 'It executes when if condition is false', 'It is optional', 'It is deprecated'], 
1, 'else executes when the if condition is false.'),

(2, 17, 'Which of the following is a valid nested if syntax?', 
ARRAY['if (condition1) if (condition2) statement;', 'if condition1 if condition2 statement;', 'if (condition1) then if (condition2) statement;', 'if condition1 then if condition2 statement;'], 
0, 'Nested if statements can be written as if (condition1) if (condition2) statement;'),

(2, 18, 'What is the output of: int x = 10; if(x > 5 && x < 15) printf("Yes");?', 
ARRAY['Yes', 'No', 'Error', 'Nothing'], 
0, 'Since x is 10, both conditions are true and "Yes" is printed.'),

(2, 19, 'Which loop is best for iterating through an array?', 
ARRAY['while', 'for', 'do-while', 'All are equal'], 
1, 'for loop is most commonly used for array iteration.'),

(2, 20, 'What is the purpose of the continue statement?', 
ARRAY['To exit a loop', 'To skip current iteration', 'To pause execution', 'To continue execution'], 
1, 'continue skips the current iteration and continues with the next one.');

-- Create a sample admin user (you'll need to create this user through Supabase Auth first)
-- Then update the user profile to be an admin
-- UPDATE user_profiles SET role = 'admin', status = 'active' WHERE email = 'admin@example.com';

-- Create a sample staff user
-- UPDATE user_profiles SET role = 'staff', status = 'active' WHERE email = 'staff@example.com'; 