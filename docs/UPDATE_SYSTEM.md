# Sistema de Atualização Automática

## Visão geral

A app consulta o backend em `/api/app/version` e compara a versão instalada com a versão publicada. Se houver atualização, um banner é mostrado ao utilizador. O utilizador pode baixar e instalar o novo APK manualmente.

## Estrutura

### Backend

| Ficheiro | Função |
|---|---|
| `app/api/app/version/route.ts` | Devolve `version.json` com a versão atual, versão mínima obrigatória, URL do APK e notas de lançamento. |
| `app/api/app/apk/route.ts` | Serve o ficheiro APK para download. |
| `public/apk/version.json` | Manifesto da versão atual. |
| `public/apk/portal-social.apk` | APK atual disponibilizado para download. |

### Flutter

| Ficheiro | Função |
|---|---|
| `lib/services/update_service.dart` | Verifica atualizações, compara versões e abre o browser para download. |
| `lib/widgets/update_banner.dart` | Banner visual com atualização obrigatória ou recomendada. |
| `lib/main.dart` | Integra o `UpdateService` e exibe o banner no topo da app. |

## Fluxo

1. A app abre e consulta `GET /api/app/version`.
2. Compara a versão instalada com:
   - `version`: se for menor → atualização recomendada.
   - `minSupportedVersion`: se for menor → atualização obrigatória.
3. Mostra o banner correspondente.
4. Ao clicar em atualizar, abre o browser para fazer download do APK.
5. O utilizador instala manualmente o APK no Android.

## Campos do `version.json`

```json
{
  "version": "1.0.1",
  "minSupportedVersion": "1.0.1",
  "apkUrl": "/apk/portal-social.apk",
  "releaseNotes": "Descrição da atualização."
}
```

## Notas

- Atualizações são bloqueadas quando a versão instalada é menor que `minSupportedVersion`.
- A app NÃO instala automaticamente o APK; o download é feito pelo browser.
- O APK deve ser copiado para `public/apk/` no backend e o `version.json` atualizado antes de cada release.
- O nome do APK no backend e na `apkUrl` devem ser iguais.
