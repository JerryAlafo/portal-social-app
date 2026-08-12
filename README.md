# PORTAL — Rede Social para Otakus
# Aplicação Flutter (Android)

Rede social moderna para a comunidade de anime e manga. Esta app espelha o funcionamento
do web app em https://portal-mz.vercel.app/.

## Stack

- Flutter 3.44+ (Dart 3.12)
- Provider (gestão de estado)
- http (cliente de API com gestão manual de cookies de sessão)
- google_sign_in (login com Google)
- shared_preferences (persistência de sessão / modo convidado)

## Como correr

```bash
# 1. Instalar dependências
flutter pub get

# 2. Executar em Android
flutter run

# 3. Compilar APK
flutter build apk --release
```

## Configuração

Cria/edita o ficheiro `.env` na raiz do projeto:

```
API_BASE_URL=https://portal-mz.vercel.app/
```

## Funcionalidades

- Registo e login (email/password) com sessão persistente
- Login com Google
- Modo convidado (navegação em conteúdo público, com restrições)
- Feed com categorias e filtros (Tudo, Seguindo, Trending, Hot, Top)
- Publicações com imagem, spoiler e conteúdo sensível
- Gostos, comentários, reposts, partilha e denúncias
- Perfis de utilizador com tabs (publicações, fanfics, galeria)
- Sistema de seguidores
- Notificações em tempo real
- Mensagens privadas (conversas)
- Eventos com interesse/presença e comentários
- Fanfics, Galeria, Notícias, Pesquisa global
- Explorar com trending e sugestões
- Configurações e painel Admin (superuser)
