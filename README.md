# C2RARS

Транслятор программ, полученных кросс-компилятором языка Си, в ассемблер симулятора RARS.

**Курсовой проект** — НИУ ВШЭ, Факультет компьютерных наук, 2025–2026  
**Автор:** Кашапов А.В., БПИ231

## Описание

C2RARS принимает на вход программу на языке Си, компилирует её RISC-V кросс-компилятором (GCC) в ассемблер, а затем трансформирует полученный код так, чтобы он корректно исполнялся в симуляторе [RARS](https://github.com/TheThirdOne/rars).

Трансформация включает:

- свёртку пар `lui`/`addi` (relocations `%hi`/`%lo`) в псевдоинструкцию `la`
  (включая загрузки/сохранения `lw`/`sw`/`flw`/`fsw`/`fld`/`fsd`)
- замену Linux-системных вызовов (`ecall` с номерами 93/94) на RARS-совместимые (exit = 10)
- подмену `ret`/`jr ra` в `main` на вызов `ecall` завершения
- замену вызовов `printf`/`puts` на RARS-сисколл `print_string`
- удаление директив, не поддерживаемых RARS (`.section`, `.align`)
- перенос данных (`.word`, `.string`, …) из `.text` в `.data`,
  с автоматической вставкой `.align 3` перед метками (8-байтовое выравнивание
  для `fld`/`fsd`)
- реорганизацию секций: `.data` → `.text` с `main` первым

Поддерживается ISA `RV32IMFD` (Integer + Multiply/Divide + RV32F + RV32D),
ABI `ilp32d`. Доступны типы `int`, `float`, `double` с честной аппаратной
арифметикой через FPU-инструкции и регистры `f0`–`f31`.

## Быстрый старт

### Зависимости

| Зависимость | Назначение |
|---|---|
| CMake >= 3.15 | система сборки |
| Flex | лексический анализатор |
| Bison >= 3.2 | синтаксический анализатор |
| RISC-V GCC (`riscv64-unknown-elf-gcc` или `riscv64-elf-gcc`) | кросс-компилятор |
| Java >= 11 | для запуска RARS (опционально, нужен для тестирования) |

**Ubuntu/Debian:**

```bash
sudo apt-get install cmake flex libfl-dev bison gcc-riscv64-unknown-elf
```

**macOS (Homebrew):**

```bash
brew install cmake flex bison riscv-elf-gcc
```

### Сборка

```bash
mkdir -p build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```

Бинарный файл: `build/src/cli/c2rars`

### Установка (опционально)

```bash
cmake --install build --prefix /usr/local
```

Это установит:
- `c2rars` в `/usr/local/bin/`
- `rars_io.h` в `/usr/local/include/c2rars/`

## Использование

```bash
c2rars -i program.c -o program.asm
```

### Параметры

| Флаг | Описание |
|---|---|
| `-i, --input <file>` | входной файл (.c или .s) |
| `-o, --output <file>` | выходной .asm файл (по умолчанию: `<имя>.asm`) |
| `-c, --compiler <name>` | имя кросс-компилятора |
| `-v, --verbose` | подробный вывод |
| `-h, --help` | справка |
| `--version` | версия |

### Выбор кросс-компилятора

Приоритет (от низшего к высшему):

1. **CMake auto-detect** — при сборке CMake ищет `riscv64-unknown-elf-gcc` / `riscv64-elf-gcc` и вкомпилирует найденный путь
2. **Переменная окружения `RISCV_GCC`** — переопределяет дефолт в runtime
3. **Флаг `-c`** — переопределяет дефолт в runtime

```bash
# Использовать конкретный компилятор
c2rars -i test.c -c riscv64-elf-gcc

# Или через переменную окружения
export RISCV_GCC=riscv64-elf-gcc
c2rars -i test.c
```

## Пример

Исходный файл `hello.c`:

```c
#include <c2rars/rars_io.h>

int main() {
    print_string("Hello, world!\n");
    return 0;
}
```

Запуск:

```bash
c2rars -i hello.c -o hello.asm
java -jar rars.jar nc hello.asm
```

Вывод:

```
Hello, world!
```

## Библиотека `rars_io.h`

Заголовочный файл `include/c2rars/rars_io.h` предоставляет обёртки над RARS-сисколлами для использования в C-коде:

Покрыты практически все RARS-сисколлы (исключая GUI-диалоги 50–59, которые
не работают в headless-режиме `nc`):

| Категория | Функции |
|---|---|
| Вывод | `print_int`, `print_float`, `print_double`, `print_string`, `print_char`, `print_int_hex`, `print_int_bin`, `print_int_unsigned` |
| Ввод | `read_int`, `read_float`, `read_double`, `read_char`, `read_string` |
| Память | `sbrk` |
| Файлы | `file_open`, `file_read`, `file_write`, `file_close` |
| Система | `rars_exit`, `get_time` / `get_time_lo`, `rars_sleep` |
| Случайные числа | `rng_set_seed`, `rand_int`, `rand_int_range`, `rand_float`, `rand_double` |

### Двухплатформенный режим (`__C2RARS__`)

`rars_io.h` собирается и под RARS, и под нативный хост — один и тот же `.c` файл
можно отлаживать локально (`cc prog.c -o prog && ./prog`), а потом запустить
через `c2rars` в RARS, не меняя исходник. Переключение управляется макросом:

- При сборке через `c2rars` макрос `__C2RARS__=1` определяется автоматически —


## Примеры

В директории `examples/` находятся демонстрационные программы:

| Файл | Описание |
|---|---|
| `01_hello.c` | вывод строки |
| `02_arithmetic.c` | арифметические операции |
| `03_loop.c` | циклы `for` и `while` |
| `04_function.c` | рекурсия (факториал, Фибоначчи, степень) |
| `05_array.c` | работа с массивами (максимум, сумма, среднее) |
| `06_multifile/` | сборка нескольких `.c` файлов |
| `07_string_input/` | ввод строк и расширенный вывод чисел (hex/bin) |
| `09_float/` | арифметика с плавающей точкой одинарной точности (RV32F) |
| `10_static.c` | глобальные и `static` переменные (`.data`, `.bss`, `.comm`) |
| `11_double/` | арифметика двойной точности (RV32D), Newton-Raphson, ряд `1/n²` |
| `12_random/` | генератор случайных чисел RARS (syscalls 40–44) |

## Тестирование

Каждый пример прогоняется двумя путями, и оба вывода сравниваются с одним
и тем же эталоном в `tests/expected_output/`:

- **RARS:** `c2rars` транслирует `.c` в `.asm`, который запускается через
  `java -jar rars.jar nc`.
- **Host:** тот же `.c` собирается нативным компилятором и просто запускается.

Если расходится хотя бы один путь — тест падает.

Запуск:

```bash
./scripts/test.sh                     # все примеры, оба пути
./scripts/test.sh -v                  # подробный вывод
./scripts/test.sh --build             # пересобрать c2rars перед запуском
./scripts/test.sh --no-rars           # пропустить RARS
./scripts/test.sh --no-host           # пропустить host
./scripts/test.sh --example 03_loop   # один пример
HOST_CC=clang ./scripts/test.sh       # выбрать хост-компилятор
```


## Структура проекта

```
├── include/
│   ├── ast.h                  # AST — узлы синтаксического дерева
│   ├── scanner.h              # интерфейс лексера (Flex)
│   └── c2rars/
│       └── rars_io.h          # RARS syscall обёртки для C
├── src/
│   ├── lexer/
│   │   └── lexer.l            # Flex-спецификация лексера
│   ├── parser/
│   │   └── parser.y           # Bison-грамматика парсера
│   ├── transformer/
│   │   ├── transformer.h      # заголовок трансформатора
│   │   └── transformer.cpp    # трансформация AST и кодогенерация
│   ├── cli/
│   │   └── main.cpp           # точка входа, CLI, пайплайн
│   └── utils/
│       ├── file_utils.h       # утилиты для работы с файлами
│       └── file_utils.cpp
├── examples/                  # демонстрационные C-программы
├── tests/
│   └── expected_output/       # эталонные выводы для тестов
├── scripts/
│   └── test.sh                # скрипт интеграционного тестирования
├── libs/                      # RARS-библиотеки (asm)
├── rars.jar                   # симулятор RARS
├── CMakeLists.txt             # корневой CMake
└── .github/workflows/ci.yml   # GitHub Actions CI
```
