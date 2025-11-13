# Лабораторная работа №5. Расширенный пайплайн в GitLab CI для Laravel

**Студент:** Богданов Юрий  
**Группа:** I2302  
**Преподаватель:** Калин Николай

**Дата:** 13.11.2025

---

## Цель работы

Получить практический опыт настройки собственного `CI/CD`-сервера с `GitLab Community Edition` и реализации конвейера для `Laravel`-приложения, включая тестирование, сборку Docker-образа и (опционально) деплой. Будет установлен `GitLab CE`, создан проект с `.gitlab-ci.yml`, настроен `Runner` и запущен пайплайн.

---

## Ход выполнения работы

### Шаг 1. Развертывание GitLab CE

Для выполнения лабораторной работы подготавливается виртуальная машина Ubuntu 24.04 Server в среде Oracle VirtualBox. Машине выделяется 4 GB оперативной памяти и 2 виртуальных процессора. Для корректной работы GitLab настраиваются два сетевых адаптера:

- Adapter 1: NAT — обеспечивает доступ виртуальной машины в Интернет.
- Adapter 2: Host-only Adapter — обеспечивает сетевое взаимодействие между хостовой и виртуальной машиной.

После запуска операционной системы IP-адрес просматривается с помощью команды:

```bash
ip a
```

Адрес, назначенный интерфейсу enp0s8 (например, 192.168.56.101), используется как внешний адрес GitLab.

![image](https://i.imgur.com/J54DMDE.png)

#### Отключение сервиса nginx

Перед установкой GitLab необходимо освободить порт 80, который используется сервисом nginx. Для этого сервис останавливается и отключается от автозагрузки командами:

```bash
sudo systemctl stop nginx
sudo systemctl disable nginx
```

![image](https://i.imgur.com/lXC7pOP.png)

#### Запуск GitLab CE в контейнере Docker

Установка GitLab выполняется с использованием Docker. Создаются постоянные тома для хранения данных и конфигурации. Контейнер GitLab запускается командой:

```bash
docker run -d \
  --hostname 192.168.56.101 \
  -p 80:80 \
  -p 443:443 \
  -p 8022:22 \
  --name gitlab \
  -e GITLAB_OMNIBUS_CONFIG="external_url='http://192.168.56.101'; gitlab_rails['gitlab_shell_ssh_port']=8022" \
  -v gitlab-data:/var/opt/gitlab \
  -v ~/gitlab-config:/etc/gitlab \
  gitlab/gitlab-ce:latest
```

![image](https://i.imgur.com/eiowZZ1.png)

#### Просмотр логов GitLab при первом запуске

После создания контейнера проверяется процесс инициализации GitLab.
Просмотр логов осуществляется командой:

```bash
docker logs -f gitlab
```

![image](https://i.imgur.com/dBvpIhU.png)

В процессе отображаются сообщения о настройке служб GitLab, генерации конфигурации, запуске компонентов и проверках состояния. Просмотр логов завершается после появления сообщений о готовности системы.

#### Получение временного пароля администратора

GitLab автоматически создаёт пароль суперпользователя при первом запуске. Пароль извлекается с помощью команды:

```bash
docker exec -it gitlab cat /etc/gitlab/initial_root_password
```

![image](https://i.imgur.com/5LbmC1R.png)

#### Первый вход в веб-интерфейс GitLab

После успешного запуска GitLab становится доступен по адресу:

```
http://192.168.56.101
```

Для входа в систему используется учётная запись root и временный пароль, полученный ранее. После первого входа `GitLab` предлагает задать новый пароль администратора.

![image](https://i.imgur.com/IRk7OrF.png)

![image](https://i.imgur.com/PYiDxQM.png)

В результате выполнения шага разворачивается и настраивается виртуальная машина, устанавливается и запускается `GitLab CE` в контейнере Docker, подготавливаются постоянные тома, извлекается пароль администратора и выполняется первый вход в веб-интерфейс `GitLab`.

### Шаг 2. Настройка `GitLab Runner`

Для выполнения конвейеров `CI/CD` требуется установить и зарегистрировать `GitLab Runner` на той же виртуальной машине, где работает `GitLab CE`.

#### Установка `GitLab Runner`

На виртуальной машине выполняется установка официального пакета `GitLab Runner`:

```bash
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt-get install -y gitlab-runner
```

![image](https://i.imgur.com/6dMTrO4.png)

Проверяется установленная версия:

```bash
gitlab-runner --version
```

![image](https://i.imgur.com/IMI8eER.png)

#### Создание instance runner в GitLab

В интерфейсе `GitLab` выполняется переход:

**Admin Area** → **CI/CD** → **Runners** → **Create instance runner**

Форма заполняется следующим образом:

| Поле                              | Значение        |
| --------------------------------- | --------------- |
| Runner description                | laravel-runner  |
| Tags                              | laravel, docker |
| Run untagged jobs                 | Включено        |
| Executor (выбирается позже в CLI) | docker          |

![image](https://i.imgur.com/idFyrci.png)

После создания отображается токен регистрации и команда для запуска.

![image](https://i.imgur.com/xBoyd2X.png)

#### Регистрация `Runner` через терминал

На виртуальной машине выполняется команда регистрации:

```bash
sudo gitlab-runner register
```

В процессе регистрации раннер последовательно запрашивает параметры. Заполненные значения:

| Параметр             | Значение                                       |
| -------------------- | ---------------------------------------------- |
| GitLab instance URL  | [http://192.168.56.101](http://192.168.56.101) |
| Authentication token | glrt-… (скопирован с GitLab)                   |
| Name                 | laravel-runner                                 |
| Tags                 | laravel, docker                                |
| Executor             | docker                                         |
| Default Docker image | php:8.2-cli                                    |

Ввод параметров выполняется в интерактивном режиме:

![image](https://i.imgur.com/3wZsCOR.png)

После завершения регистрации конфигурация автоматически сохраняется в файле:

```
/etc/gitlab-runner/config.toml
```

#### Запуск и проверка состояния `GitLab Runner`

Служба `GitLab Runner` запускается и проверяется:

```bash
sudo gitlab-runner start
sudo gitlab-runner status
```

![image](https://i.imgur.com/B8VAYDU.png)

Состояние `Service is running` подтверждает корректную работу раннера.

#### Проверка раннера в административной панели GitLab

В разделе **Admin Area** → **CI/CD** → **Runners** появляется новый `Runner` со статусом **Online**.

![image](https://i.imgur.com/pSA2eBt.png)

### Шаг 3. Создание проекта и репозитория в GitLab

Для подготовки Laravel-приложения к работе в конвейере CI/CD необходимо создать новый проект в GitLab, загрузить исходники Laravel, подготовить тестовое окружение и добавить конфигурацию `.gitlab-ci.yml`.

#### Создание нового проекта в GitLab

В интерфейсе GitLab выполняется переход:

**Repository** → **New** → **Create blank project**

Поля формы заполняются следующим образом:

| Поле                              | Значение    |
| --------------------------------- | ----------- |
| Project name                      | laravel-app |
| Namespace                         | root        |
| Visibility                        | Private     |
| Initialize repository with README | Включено    |

После создания отображается пустой репозиторий с файлом README.md.

![image](https://i.imgur.com/bJu37Pp.png)

#### Клонирование репозитория на виртуальную машину

Для подготовки к разработке необходимо клонировать проект в локальную файловую систему:

```bash
git clone http://192.168.56.101/root/laravel-app.git ~/laravel-app
cd ~/laravel-app
```

GitLab запрашивает логин и пароль пользователя root.

![image](https://i.imgur.com/X9Vqyot.png)

#### Загрузка исходников `Laravel` в проект

Официальный шаблон `Laravel` скачивается в отдельную директорию:

```bash
git clone https://github.com/laravel/laravel.git ~/laravel
```

После загрузки файлы `Laravel` копируются в проект GitLab:

```bash
cp laravel/* laravel-app/ -r
```

Структура проекта обновляется и включает стандартный набор директорий `Laravel`.

![image](https://i.imgur.com/eRsZRob.png)

#### Создание Dockerfile

В корне проекта создаётся `Dockerfile`, описывающий контейнер `Laravel`, с помощью команды:

```bash
nano Dockerfile
```

и содержимым:

```dockerfile
# Используем официальный образ PHP с Apache
FROM php:8.2-apache

# Устанавливаем зависимости
RUN apt-get update && apt-get install -y \
    libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath

# Устанавливаем Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Копируем код приложения
COPY . /var/www/html
RUN composer install --no-scripts --no-interaction
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage

# Настраиваем Apache
RUN a2enmod rewrite
EXPOSE 80

CMD ["apache2-foreground"]
```

![image](https://i.imgur.com/HeCQ6AT.png)

#### Создание файла `.env.testing`

Для выполнения тестов в пайплайне `GitLab` требуется создать файл окружения `.env.testing`, с помощью команды:

```bash
nano .env.testing
```

и содержимым:

```env
APP_NAME=Laravel
APP_ENV=testing
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost
APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=en_US
APP_MAINTENANCE_DRIVER=file
PHP_CLI_SERVER_WORKERS=4
BCRYPT_ROUNDS=12
LOG_CHANNEL=stack
LOG_STACK=single
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel_test
DB_USERNAME=root
DB_PASSWORD=root
SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=null
BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local
QUEUE_CONNECTION=database
CACHE_STORE=database
MEMCACHED_HOST=127.0.0.1
REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
MAIL_MAILER=log
MAIL_SCHEME=null
MAIL_HOST=127.0.0.1
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"
```

![image](https://i.imgur.com/ymImaoe.png)

#### Добавление теста ExampleTest

Если тесты отсутствуют, необходимо создать файл `tests/Unit/ExampleTest.php`, с помощью команды:

```bash
nano tests/Unit/ExampleTest.php
```

и содержимым:

```php
<?php
namespace Tests\Unit;
use PHPUnit\Framework\TestCase;
class ExampleTest extends TestCase
{
    public function testBasicTest()
    {
        $this->assertTrue(true);
    }
}
```

![image](https://i.imgur.com/bO8ndT8.png)

#### Создание файла `.gitlab-ci.yml`

В корне проекта создаётся файл `.gitlab-ci.yml`, с помощью команды:

```bash
nano .gitlab-ci.yml
```

и содержимым:

```yaml
stages:
  - test
  - build
services:
  - mysql:8.0
variables:
  MYSQL_DATABASE: laravel_test
  MYSQL_ROOT_PASSWORD: root
  DB_HOST: mysql
test:
  stage: test
  image: php:8.2-cli
  before_script:
    - apt-get update -yqq
    - apt-get install -yqq libpng-dev libonig-dev libxml2-dev libzip-dev unzip git
    - docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath
    - curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    - composer install --no-scripts --no-interaction
    - cp .env.testing .env
    - php artisan key:generate
    - php artisan migrate --seed
    - cp .env .env.testing
    - php artisan config:clear
  script:
    - vendor/bin/phpunit
  after_script:
    - rm -f .env
```

![image](https://i.imgur.com/aT5sF6r.png)

#### Коммит и отправка проекта в `GitLab`

После создания всех файлов проект нужно отправить в репозиторий:

```bash
git add .
git commit -m "Add Laravel app with CI/CD config"
git push -u origin main
```

![image](https://i.imgur.com/nebtPSU.png)
![image](https://i.imgur.com/hkbPTuT.png)

Файлы успешно добавлены!

![image](https://i.imgur.com/VQOL1WI.png)

### Шаг 4. Запуск и проверка конвейера GitLab CI/CD

После добавления файла `.gitlab-ci.yml` и отправки всех изменений в репозиторий, `GitLab` автоматически запускает конвейер `CI/CD`.

#### Запуск пайплайна

Переход нужно выполнить в меню проекта:

**Build** → **Pipelines**

В списке отображаются созданные пайплайны, каждый из которых выполняется при пуше в ветку `main`.

Статус пайплайна меняется автоматически:

- **pending** — ожидает свободного Runner
- **running** — Runner начал выполнение
- **passed / failed** — выполнение успешно / с ошибкой

#### Просмотр выполнения job `test`

После того как Runner приступает к работе, открывается подробный лог выполнения job.

![image](https://i.imgur.com/6sHBToD.png)

В процессе запуска выполняются:

- установка зависимостей PHP;
- установка Composer;
- загрузка пакетов Laravel;
- запуск миграций `php artisan migrate --seed`;
- запуск теста `vendor/bin/phpunit`.

#### Исправление ошибок и повторный запуск

Первый тест завершился ошибкой из-за некорректной структуры файла `ExampleTest.php`.
Файл был исправлен, после чего выполнена команда:

```bash
git add .
git commit -m "Recreate ExampleTest for CI"
git push
```

GitLab автоматически создал новый пайплайн.

#### Успешное прохождение пайплайна

После исправления тестов job `test` завершился статусом **Job succeeded**.

![image](https://i.imgur.com/TMSqDBI.png)

Все проверки прошли успешно, что подтверждает корректность настроенного `CI/CD`-процесса.

### Шаг 5. Итоговая проверка работы `GitLab CI/CD`

После успешного выполнения пайплайна необходимо убедиться, что `GitLab` корректно обрабатывает проект `Laravel`, а инфраструктура `CI/CD` функционирует стабильно.

#### Проверка истории пайплайнов

В разделе проекта выполняется переход:

**Build** → **Pipelines**

В списке отображаются ранее запущенные пайплайны.
Последний пайплайн должен имеет статус:

- **passed**

Это подтверждает корректное выполнение тестов PHPUnit и работу Runner.

![image](https://i.imgur.com/LD19L1c.png)

#### Финальная проверка конфигурации проекта

Дополнительно проверяется состояние инфраструктуры:

- Runner отображается в `Admin Area → CI/CD → Runners` со статусом **Online**.
- Репозиторий содержит необходимые файлы:

  - `Dockerfile`
  - `.env.testing`
  - `.gitlab-ci.yml`
  - тест `tests/Unit/ExampleTest.php`

- Пайплайн запускается автоматически при каждом `git push`.

В результате выполнения финальной проверки подтверждается, что проект `Laravel` корректно настроен, `GitLab Runner` функционирует, а конвейер `CI` успешно выполняет тестовое окружение.

## Вывод

В ходе выполнения лабораторной работы была полностью развернута и настроена инфраструктура для автоматизации процессов `CI/CD` на базе `GitLab CE`. На виртуальной машине был успешно установлен `GitLab Community Edition`, подготовлено рабочее окружение и произведён первый вход в систему. Далее был установлен и зарегистрирован `GitLab Runner`, который обеспечил выполнение задач конвейера в Docker-окружении.

Был создан новый проект `Laravel`, загружены его исходные файлы, подготовлен Dockerfile, файл окружения `.env.testing`, а также тестовый класс `ExampleTest`. В корне проекта создан и настроен файл `.gitlab-ci.yml`, определяющий этапы конвейера, использование MySQL-сервиса, установку необходимых PHP-зависимостей и запуск PHPUnit-тестов.

После отправки проекта в репозиторий `GitLab` конвейер автоматически запустился. В процессе работы были обнаружены и исправлены ошибки в тестах, после чего пайплайн завершился успешно. Это подтверждает корректность настройки `GitLab Runner`, правильность конфигурации `.gitlab-ci.yml` и корректную работу тестового окружения `Laravel` внутри `CI`.

В результате работы был получен практический опыт развертывания `GitLab CE`, настройки `Runner`, создания проекта с использованием `Laravel` и построения `CI`-конвейера, который автоматически выполняет тестирование приложения. Настроенная `CI/CD`-система демонстрирует готовность проекта к дальнейшему расширению, включая сборку Docker-образов и развёртывание приложения.
