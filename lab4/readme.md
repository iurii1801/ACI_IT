# Лабораторная работа №4. Автоматизация развертывания многоконтейнерного приложения с Docker Compose с использованием Ansible.

**Студент:** Богданов Юрий  
**Группа:** I2302  
**Преподаватель:** Калин Николай

**Дата:** 31.10.2025

---

## Цель работы

Закрепить знания по **Docker** и **Docker Compose** путем автоматизации их установки и развертывания на удаленных виртуальных машинах с помощью **Ansible**. Студенты научатся объединять инструменты конфигурационного управления (**Ansible**) с контейнеризацией (**Docker**), создавая **reproducible** инфраструктуру. Это позволит понять, как в реальных сценариях **DevOps Ansible** используется для оркестрации контейнеров на нескольких хостах.

---

## Ход выполнения работы

### Плейбук 1. «Установка Docker и Docker Compose»

### Шаг 1. Проверка установки Ansible и подготовка проекта

Для начала устанавливаем Ansible и создаём структуру каталогов для проекта:

```bash
sudo apt update
sudo apt install -y ansible
mkdir -p ~/ansible-docker-lab/files
cd ~/ansible-docker-lab
```

![image](https://i.imgur.com/X7CkT3x.png)

Проверяем корректность установки:

```bash
ansible --version
```

![image](https://i.imgur.com/jN8YNo5.png)

### Шаг 2. Настройка файла инвентаря

Создаём файл `inventory.ini`, указывающий, что Ansible будет работать с **локальной машиной**:

```ini
[docker_hosts]
localhost ansible_connection=local
```

![image](https://i.imgur.com/s6SMRGs.png)

### Шаг 3. Создание плейбука для установки Docker

Создаём файл `install_docker.yml`, который выполняет установку всех необходимых компонентов:

```yaml
---
- name: Install Docker and Docker Compose on Ubuntu
  hosts: docker_hosts
  become: true

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install required dependencies
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg
          - lsb-release
        state: present

    - name: Add Docker’s official GPG key
      ansible.builtin.get_url:
        url: https://download.docker.com/linux/ubuntu/gpg
        dest: /etc/apt/keyrings/docker.gpg
        mode: '0644'

    - name: Add Docker repository
      ansible.builtin.apt_repository:
        repo: "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
        state: present
        filename: docker

    - name: Update apt cache after adding Docker repo
      apt:
        update_cache: yes

    - name: Install Docker Engine and Compose plugin
      apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-buildx-plugin
          - docker-compose-plugin
        state: present

    - name: Ensure docker service is enabled and started
      service:
        name: docker
        state: started
        enabled: yes

    - name: Add current user to docker group
      user:
        name: "{{ lookup('env', 'USER') }}"
        groups: docker
        append: yes
```

### Шаг 4. Запуск плейбука

Команда для выполнения установки Docker:

```bash
ansible-playbook -i inventory.ini install_docker.yml --ask-become-pass
```

![image](https://i.imgur.com/u5L5nH3.png)

---

### Шаг 5. Проверка установки Docker

После завершения выполнения плейбука необходимо проверить версию Docker и Compose:

```bash
docker --version
docker compose version
```

![image](https://i.imgur.com/LBGIKe7.png)

На данном этапе было выполнено:

- Установлены пакеты Docker CE, CLI, containerd и плагин Compose.
- Сервис Docker автоматически запущен и добавлен в автозагрузку.
- Пользователь включён в группу `docker` для работы без `sudo`.
- Проверена корректная установка Docker и Docker Compose.

**Плейбук 1 выполнен успешно.**

---

## Плейбук 2. «Создание и тестирование многоконтейнерного приложения WordPress + MySQL»

### Шаг 1. Создание файла `docker-compose.yml`

В каталоге проекта `~/ansible-docker-lab/files` создаём файл **docker-compose.yml**, который описывает два контейнера — базу данных `db` и CMS `wordpress`.

```yaml
services:
  db:
    image: mysql:8.0
    container_name: wp_db
    restart: always
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
      MYSQL_ROOT_PASSWORD: rootpass
    volumes:
      - db_data:/var/lib/mysql

  wordpress:
    image: wordpress:latest
    container_name: wp_app
    depends_on:
      - db
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress

volumes:
  db_data:
```

### Шаг 2. Запуск приложения локально

Для проверки работоспособности создаём и запускаем контейнеры вручную:

```bash
docker compose -f files/docker-compose.yml up -d
```

![image](https://i.imgur.com/csyE6vZ.png)
![image](https://i.imgur.com/fUsGgSf.png)

### Шаг 3. Проверка состояния контейнеров

После успешной загрузки контейнеров проверяем их статус:

```bash
docker ps
```

Результат должен содержать два контейнера:

- `wp_app` (WordPress)
- `wp_db` (MySQL)

![image](https://i.imgur.com/BmvtsOT.png)

### Шаг 4. Проверка работы WordPress

После запуска контейнеров необходимо убедиться, что веб-интерфейс WordPress доступен в браузере по адресу:

```
http://127.0.0.1:8080
```

На экране должна появиться страница установки WordPress (выбор языка интерфейса).

![image](https://i.imgur.com/BUisgaP.png)

### Шаг 5. Остановка и очистка контейнеров

После тестирования приложение можно остановить и удалить созданные контейнеры и сеть:

```bash
docker compose down
```

На данном этапе было выполнено:

- Создан многоконтейнерный стек WordPress + MySQL.
- Приложение успешно развёрнуто локально с помощью Docker Compose.
- Доступ к WordPress подтверждён через браузер.
- Проверена корректная работа контейнеров и взаимодействие между ними.

**Плейбук 2 выполнен успешно.**

---

## Плейбук 3. «Автоматизация развертывания Docker Compose с помощью Ansible»

> *Ранее (во втором плейбуке) контейнеры `WordPress` и `MySQL` запускались вручную с помощью команды `docker compose up -d` для тестирования их работоспособности.
> В данном этапе процесс полностью автоматизирован через `Ansible`, что позволяет выполнять деплой без ручных действий.*

### Шаг 1. Создание плейбука `deploy_compose.yml`

Создаём файл `deploy_compose.yml` в корне проекта `~/ansible-docker-lab/`, который выполняет следующие задачи:

1. Создаёт каталог `/opt/wordpress` на удалённой машине.
2. Копирует туда `docker-compose.yml`.
3. Запускает контейнеры через `docker compose up -d`.
4. Проверяет, что контейнеры успешно запущены.

```yaml
---
- name: Deploy docker compose stack
  hosts: docker_hosts
  become: true

  vars:
    project_path: /opt/wordpress

  tasks:
    - name: Ensure project directory exists
      file:
        path: "{{ project_path }}"
        state: directory
        mode: "0755"

    - name: Copy docker-compose.yml to remote host
      copy:
        src: files/docker-compose.yml
        dest: "{{ project_path }}/docker-compose.yml"
        mode: "0644"

    - name: Run docker compose up
      command: docker compose -f {{ project_path }}/docker-compose.yml up -d
      args:
        chdir: "{{ project_path }}"

    - name: Check running containers
      command: docker ps
      register: containers

    - name: Show containers
      debug:
        var: containers.stdout_lines
```

### Шаг 2. Запуск плейбука

Выполняем плейбук с повышенными правами:

```bash
ansible-playbook -i inventory.ini deploy_compose.yml --ask-become-pass
```

![image](https://i.imgur.com/awLgFuL.png)

### Шаг 3. Проверка результата

Плейбук автоматически выводит список запущенных контейнеров:

```
CONTAINER ID   IMAGE             STATUS        PORTS
721ff77efedb   wordpress:latest  Up 3 minutes  0.0.0.0:8080->80/tcp
dbd8a0adecc6   mysql:8.0         Up 3 minutes  3306/tcp
```

Это подтверждает успешный запуск `WordPress` и `MySQL`.

На данном этапе было выполнено:

- Файл `docker-compose.yml` успешно скопирован на удалённый хост.
- Контейнеры `wp_app` и `wp_db` автоматически запущены через Ansible.
- Проверка показала, что оба контейнера работают корректно.
- Процесс деплоя теперь полностью автоматизирован.

**Плейбук 3 выполнен успешно.**

---

### Вывод

В ходе выполнения лабораторной работы №4 были изучены и применены технологии **Docker**, **Docker Compose** и **Ansible** для автоматизации развёртывания многоконтейнерных приложений.
На практике реализован полный цикл подготовки инфраструктуры: установка Docker и Compose, создание и тестирование стека WordPress + MySQL, а затем его автоматический деплой средствами Ansible.
Все задачи выполнены корректно, контейнеры успешно запускаются и взаимодействуют между собой, а процесс установки и развёртывания стал полностью автоматизированным.
Работа позволила закрепить навыки конфигурационного управления, оркестрации контейнеров и интеграции инструментов DevOps для создания воспроизводимой и масштабируемой инфраструктуры.
