# Снегурочки Москва

Репозиторий: https://github.com/kabuto-lab/sneg. Основной домен:
https://snegurochkimoscow.com. Домены `.ru` и `www` перенаправляются на основной.

Рабочая версия перенесена из `meremarina51-ctrl/snegurochka` с сохранением истории,
включая исправления до `7412b4164d8f7432bcbe0494b80f2c86486f435f`.
Локальный прототип со стеклом и шарами в этот репозиторий не включён.

Разработка: Node.js 22, `corepack yarn install --frozen-lockfile`, затем
`corepack yarn dev`. Версия Yarn закреплена в `package.json`.

Выкладка на Zomro после коммита: `git push origin main`, затем
`.\ops\deploy.ps1`. [Устройство выкладки и доменов](DEPLOYMENT.md).

Ниже — исходная справка Next.js.

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
