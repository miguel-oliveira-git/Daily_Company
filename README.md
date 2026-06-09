# daily_company

Este é o projeto Flutter do Daily Company.

## Como compartilhar com o grupo

1. Crie um repositório Git e faça o push do código-fonte.
2. Adicione seus colegas como colaboradores no GitHub (ou GitLab/Bitbucket).
3. Cada membro deve clonar o repositório e instalar as dependências.

## Arquivos que não devem ser enviados

O projeto já ignora estes arquivos no `.gitignore`:

- `.env`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Esses arquivos contêm dados de configuração e chaves do Firebase.

## Configuração do Firebase no time

O mais simples para o grupo é usar um único projeto Firebase compartilhado.

1. No Firebase Console, adicione os membros do time como usuários do projeto.
2. Gere os dados de configuração para cada plataforma.
3. Preencha um arquivo `.env` local com os valores do Firebase.

## Passos para rodar o projeto

1. Clone o repositório:
   ```bash
   git clone <REPO_URL>
   cd daily_company
   ```
2. Copie o template de ambiente:
   - macOS/Linux:
     ```bash
     cp .env.example .env
     ```
   - Windows PowerShell:
     ```powershell
     Copy-Item .env.example .env
     ```
3. Preencha o arquivo `.env` com os valores do Firebase do projeto compartilhado.
4. Instale as dependências:
   ```bash
   flutter pub get
   ```
5. Rode o app:
   ```bash
   flutter run
   ```

## Observações importantes

- Nunca envie o arquivo `.env` no repositório.
- Se algum colega precisar usar um Firebase próprio, ele pode criar o `.env` local com as próprias chaves.
- Os dados do Firebase são carregados através do `.env` em `lib/firebase_options.dart`.
