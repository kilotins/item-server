# Entra ID-integration for Coolify

Koppla Coolify mot Entra ID (Azure AD) så teamet loggar in med sina Item-konton.

## 1. Skapa App Registration i Azure-portalen

1. Gå till [Azure Portal → App registrations](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade)
2. Klicka **New registration**
   - Name: `Item Server - Coolify`
   - Supported account types: **Single tenant** (bara Item)
   - Redirect URI: **Web** → `https://coolify.item.lan/auth/callback`
3. Klicka **Register**

## 2. Notera credentials

På app-sidan, kopiera:
- **Application (client) ID**
- **Directory (tenant) ID**

Skapa en client secret:
1. Gå till **Certificates & secrets → New client secret**
2. Description: `Coolify`
3. Expires: 24 months
4. Kopiera **Value** (visas bara en gång!)

## 3. Konfigurera API permissions

1. Gå till **API permissions**
2. Klicka **Add a permission → Microsoft Graph → Delegated permissions**
3. Lägg till:
   - `openid`
   - `profile`
   - `email`
4. Klicka **Grant admin consent for Item**

## 4. Konfigurera Coolify

1. Logga in som admin på `https://coolify.item.lan:8000`
2. Gå till **Settings → OAuth**
3. Välj **Microsoft** / **Azure AD**
4. Fyll i:
   - **Client ID:** (från steg 2)
   - **Client Secret:** (från steg 2)
   - **Tenant ID:** (från steg 2)
5. Spara

## 5. Testa

1. Öppna Coolify i ett privat fönster
2. Klicka **Login with Microsoft**
3. Logga in med ditt Item-konto

## Användarhantering

- **Ny anställd:** Lägg till i Entra → kan logga in direkt i Coolify
- **Slutar:** Inaktivera i Entra → ute ur Coolify automatiskt
- **Team-tilldelning:** Gör i Coolify UI efter första inloggning (logpilot, enonic, sandbox)

## Felsökning

| Problem | Lösning |
|---------|---------|
| Redirect URI mismatch | Kontrollera att URI i Azure matchar exakt: `https://coolify.item.lan/auth/callback` |
| Consent saknas | Klicka "Grant admin consent" i API permissions |
| Client secret har gått ut | Skapa ny secret i Azure, uppdatera i Coolify |
