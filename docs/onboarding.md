# Kom igång med Item Server

## Vad är detta?

Item Server är vår interna utvecklingsplattform. Du kan deploya appar, API:er och prototyper med `git push` — de blir automatiskt live med HTTPS på `dittnamn.item.lan`.

## Förutsättningar

- GitHub-konto kopplat till Item
- Item Entra ID-konto (ditt vanliga Item-login)
- Git installerat lokalt

## 1. Skapa ett nytt projekt (2 min)

### Alternativ A: Använd vår mall
```bash
gh repo create item/mitt-projekt --template item/starter --private --clone
cd mitt-projekt
```

### Alternativ B: Eget projekt med Dockerfile
```bash
mkdir mitt-projekt && cd mitt-projekt
git init
```

Skapa en `Dockerfile`:
```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]
```

## 2. Koppla i Coolify (3 min)

1. Gå till **https://coolify.item.lan:8000**
2. Logga in med ditt Item-konto
3. Välj team **sandbox**
4. Klicka **New Resource → Public/Private Repository**
5. Välj ditt GitHub-repo
6. Sätt domän: `mitt-projekt.item.lan`
7. Klicka **Deploy**

## 3. Pusha och deploya (30 sek)

```bash
git add .
git commit -m "First deploy"
git push
```

Klart! Appen är live på `https://mitt-projekt.item.lan`

## Behöver du en databas?

1. I Coolify → **New Resource → Database**
2. Välj PostgreSQL, Redis, MySQL, MongoDB...
3. Coolify ger dig connection string
4. Lägg den som environment variable i din app

## Vanliga ramverk

### Node.js / Express
Exponera på port 3000, Coolify fixar resten.

### Python / FastAPI
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```
Sätt port till 8000 i Coolify.

### Next.js / React
```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-alpine
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json .
EXPOSE 3000
CMD ["npm", "start"]
```

### Statisk sida (HTML/CSS/JS)
```dockerfile
FROM nginx:alpine
COPY . /usr/share/nginx/html
EXPOSE 80
```
Sätt port till 80 i Coolify.

## Environment Variables

- **Aldrig** committa `.env`-filer med riktiga lösenord
- Lägg variabler i Coolify UI: App → Environment Variables
- Använd `.env.example` i repot för dokumentation

## Felsökning

| Problem | Lösning |
|---------|---------|
| Appen startar inte | Kolla build-loggen i Coolify UI |
| Domänen fungerar inte | Vänta 30 sek, DNS behöver propagera |
| Port fungerar inte | Kontrollera att EXPOSE i Dockerfile matchar port i Coolify |
| Behöver hjälp | Fråga Eric eller skriv i #dev-server på Slack |

## Tips

- Använd **tmux** om du SSH:ar in på servern (`tmux new -s mysession`)
- Se alla körande appar: `docker ps` på servern
- Coolify har inbyggda loggar och monitoring per app
