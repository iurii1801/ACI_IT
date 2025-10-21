# Лабораторная работа №3

**Студент:** Богданов Юрий  
**Группа:** I2302  
**Преподаватель:** Калин Николай

**Дата:** 21.10.2025

---

## Цель работы

Целью лабораторной работы является освоение работы с системой автоматизации **Ansible**, включая установку и настройку веб-сервера Nginx, а также автоматизацию создания системного пользователя с доступом по SSH-ключу и правами `sudo` без запроса пароля.

Работа состоит из двух частей:

1. Настройка **статического сайта через Nginx** с помощью плейбука.
2. Создание пользователя **deploy** и настройка доступа по ключу с использованием второго плейбука.

---

## Ход выполнения работы

## Плейбук 1. «Статический сайт через Nginx + распаковка архива»

**Цель:** установить `nginx`, распаковать мини-сайт из архива `.tar.gz` в web-директорию и настроить виртуальный хост.

---

### Шаг 1. Установка и проверка Ansible

Для начала необходимо установить систему автоматизации **`Ansible`**, создать рабочую структуру проекта и убедиться, что она корректно функционирует.

#### Обновление пакетов и установка Ansible

```bash
sudo apt update
sudo apt install -y ansible
```

После завершения установки необходимо создать каталоги для проекта:

```bash
mkdir -p ~/ansible/{playbooks,files}
cd ~/ansible
```

![image](https://i.imgur.com/Dbhs6pw.png)
![image](https://i.imgur.com/HYfAXCj.png)

#### Проверка версии Ansible

```bash
ansible --version
```

#### Создание файла инвентаря (inventory)

Необходимо создать файл `inventory`, в котором необходимо указать, что Ansible будет работать с **локальным хостом**:

```bash
cat > ~/ansible/inventory <<'EOF'
[web]
localhost ansible_connection=local
EOF
```

#### Проверка соединения с хостом

Команда для теста соединения:

```bash
ansible -i ~/ansible/inventory web -m ping
```

Результат успешного подключения:

```bash
localhost | SUCCESS => {"ping": "pong"}
```

![image](https://i.imgur.com/JZWwyuq.png)

На данном этапе было выполнено:

* Установка Ansible и необходимых зависимостей.
* Создание структуры проекта `~/ansible`.
* Настройка файла `inventory` для локального хоста.
* Проверка успешной работы Ansible с помощью команды `ping`.

**`Ansible` успешно установлен и готов к использованию.**

---

### Шаг 2. Развёртывание статического сайта через Nginx

На этом этапе необходимо подготовить минимальный сайт, упаковать его в архив `.tar.gz`, создать конфигурацию виртуального хоста для Nginx и автоматизировать развёртывание через Ansible.

#### Подготовка файлов сайта и архива

Необходимо создать простую HTML-страницу, упаковать её в архив и подготовить файл конфигурации `mysite.conf` для `Nginx`:

```bash
mkdir -p ~/ansible/site ~/ansible/files

# простой сайт
cat > ~/ansible/site/index.html <<'EOF'
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>MySite</title></head>
  <body style="font-family:sans-serif">
    <h1>It works!</h1>
    <p>Served by nginx from /var/www/mysite</p>
  </body>
</html>
EOF

# упаковка сайта в архив для модуля unarchive
tar -czf ~/ansible/files/site.tar.gz -C ~/ansible/site .

# vhost для nginx
cat > ~/ansible/files/mysite.conf <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    root /var/www/mysite;
    index index.html;

    access_log /var/log/nginx/mysite_access.log;
    error_log  /var/log/nginx/mysite_error.log;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
```

![image](https://i.imgur.com/dc9mMTq.png)

Проверка, что файлы добавлены в каталог `files`:

```bash
ls -l ~/ansible/files
```

![image](https://i.imgur.com/U1fxwcQ.png)

#### Создание плейбука для развёртывания сайта

Файл `~/ansible/playbooks/01_static_site.yml` автоматизирует все этапы развёртывания Nginx и сайта.

```yaml
cat > ~/ansible/playbooks/01_static_site.yml <<'YAML'
---
- name: Static site via nginx
  hosts: web
  become: true
  vars:
    web_root: /var/www/mysite
    sa: /etc/nginx/sites-available
    se: /etc/nginx/sites-enabled
    vhost_name: mysite.conf

  tasks:
    - name: Update apt cache
      apt:
        update_cache: true

    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Ensure web root exists
      file:
        path: "{{ web_root }}"
        state: directory
        owner: www-data
        group: www-data
        mode: "0755"

    - name: Unarchive site into web root
      unarchive:
        src: ../files/site.tar.gz
        dest: "{{ web_root }}"
        owner: www-data
        group: www-data
        mode: "0755"
      notify: validate and reload nginx

    - name: Place vhost into sites-available
      copy:
        src: ../files/{{ vhost_name }}
        dest: "{{ sa }}/{{ vhost_name }}"
        owner: root
        group: root
        mode: "0644"
      notify: validate and reload nginx

    - name: Disable default site
      file:
        path: "{{ se }}/default"
        state: absent
      notify: validate and reload nginx

    - name: Enable site (symlink)
      file:
        src: "{{ sa }}/{{ vhost_name }}"
        dest: "{{ se }}/{{ vhost_name }}"
        state: link
      notify: validate and reload nginx

    - name: Ensure nginx is running and enabled
      service:
        name: nginx
        state: started
        enabled: true

  handlers:
    - name: validate and reload nginx
      shell: |
        nginx -t
        systemctl reload nginx
      become: true
YAML
```

#### Запуск плейбука

Выполняем плейбук с повышением прав:

```bash
ansible-playbook -i ~/ansible/inventory ~/ansible/playbooks/01_static_site.yml -K
```

![image](https://i.imgur.com/4tHLjEi.png)

#### Проверка работы Nginx

Проверяем статус службы и доступность сайта:

```bash
systemctl status nginx --no-pager
sudo nginx -t
curl -I http://localhost/
```

![image](https://i.imgur.com/yHy08Hp.png)
![image](https://i.imgur.com/SGtg83E.png)

Для проверки необходимо зайти в браузер и проверить отображение сайта по адресу `http://127.0.0.1`:

![image](https://i.imgur.com/mbMipRR.png)

На данном этапе было выполнено:

* Установлен и запущен веб-сервер Nginx.
* Развёрнут статический сайт из архива `site.tar.gz`.
* Создан виртуальный хост `mysite.conf`.
* Сайт успешно открывается в браузере по адресу `http://localhost`.

---

## Плейбук 2. «Создание пользователя deploy и настройка SSH-доступа»

**Цель:**
Автоматизировать создание пользователя **deploy**, выдать ему права `sudo` без запроса пароля, а также разрешить вход по SSH-ключу.

---

### Шаг 3. Создание пользователя deploy и настройка SSH-ключа

#### Генерация SSH-ключа

Для начала необходимо создать пару ключей — приватный и публичный.
Команда автоматически создаст их в директории `~/.ssh`:

```bash
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
```

![image](https://i.imgur.com/GDL2lmJ.png)

---

#### Копирование публичного ключа

Чтобы использовать его в плейбуке, необходимо скопировать публичный ключ в директорию `files` под именем `deploy.pub`:

```bash
cp ~/.ssh/id_ed25519.pub ~/ansible/files/deploy.pub
```

![image](https://i.imgur.com/lGb8P4X.png)

---

#### Создание плейбука для пользователя deploy

Файл `~/ansible/playbooks/02_deploy_user.yml` необходимо создать через `heredoc`-команду:

```bash
cat > ~/ansible/playbooks/02_deploy_user.yml <<'YAML'
---
- name: Deploy user with SSH key and sudoers drop-in
  hosts: web
  become: true
  vars:
    deploy_user: deploy
    sudoers_dropin: /etc/sudoers.d/deploy
    deploy_pubkey: "{{ lookup('file', '../files/deploy.pub') }}"

  tasks:
    - name: Create deploy user and add to sudo
      user:
        name: "{{ deploy_user }}"
        shell: /bin/bash
        groups: sudo
        append: true
        create_home: true
        password_lock: true

    - name: Authorize SSH key
      authorized_key:
        user: "{{ deploy_user }}"
        key: "{{ deploy_pubkey }}"
        state: present
        manage_dir: true

    - name: Write sudoers drop-in (validate with visudo)
      copy:
        dest: "{{ sudoers_dropin }}"
        owner: root
        group: root
        mode: "0440"
        content: |
          {{ deploy_user }} ALL=(ALL) NOPASSWD:ALL
        validate: 'visudo -cf %s'
YAML
```

#### Запуск плейбука

Необходимо выполнить плейбук с правами суперпользователя:

```bash
ansible-playbook -i ~/ansible/inventory ~/ansible/playbooks/02_deploy_user.yml -K
```

![image](https://i.imgur.com/cmX2Sxe.png)

#### Проверка созданного пользователя

Необходимо проверить, что пользователь **deploy** существует и входит в группу `sudo`:

```bash
id deploy
```

![image](https://i.imgur.com/VloJaVd.png)

#### Проверка SSH-доступа и прав sudo

Можно попробовать подключиться к пользователю `deploy` и выполнить команду без пароля:

```bash
ssh deploy@localhost
sudo -n true && echo OK
```

![image](https://i.imgur.com/uVGdcxL.png)

На данном этапе было выполнено:

* Сгенерированы SSH-ключи для авторизации.
* Создан пользователь **deploy** с домашним каталогом и членством в группе `sudo`.
* Настроен вход по публичному ключу.
* Добавлен drop-in файл в `/etc/sudoers.d/`, разрешающий выполнение команд `sudo` без запроса пароля.
* Проверено, что пользователь может выполнять `sudo` без пароля.

**Все задачи плейбука 2 успешно выполнены.**

---

## Вывод

В ходе выполнения лабораторной работы №3 была изучена система автоматизации **Ansible** и её применение для автоматического развертывания и настройки серверных компонентов. В процессе работы были созданы и выполнены два плейбука. Первый плейбук автоматизировал установку и настройку веб-сервера **Nginx**, распаковку статического сайта из архива и настройку виртуального хоста, после чего сайт стал доступен по адресу `http://localhost`. Второй плейбук позволил создать пользователя **deploy**, настроить для него вход по SSH-ключу и предоставить права суперпользователя без запроса пароля через отдельный конфигурационный файл в `/etc/sudoers.d`. Все задачи выполнены корректно, плейбуки отработали без ошибок, и их результат подтверждён проверками в системе. В результате выполнения работы была закреплена практика использования **Ansible** для автоматизации рутинных операций, настройки серверов и управления пользователями. Работа показала, что применение Ansible значительно упрощает администрирование и обеспечивает воспроизводимость действий при развертывании инфраструктуры.
