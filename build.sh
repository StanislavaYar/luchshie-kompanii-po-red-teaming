#!/usr/bin/env bash
# Red Team Rating — static build.
# Sources: flat folder src/ (header, footer, content-*.html, schema-*.json, rtr.css, rtr.js, favicon.svg)
# Output:  docs/  (GitHub Pages staging from /docs; zip of docs/ goes to production hosting)
# All internal links in output are relative (no leading slash). Canonical/og/sitemap use the production domain.
set -euo pipefail
cd "$(dirname "$0")"

DOMAIN="https://luchshie-kompanii-po-red-teaming.com"
SRC="src"
OUT="docs"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

rm -rf "$OUT"
mkdir -p "$OUT/assets" "$OUT/fonts"
cp "$SRC/rtr.css" "$SRC/rtr.js" "$OUT/assets/"
cp fonts/*.woff2 "$OUT/fonts/"
cp "$SRC/favicon.svg" "$OUT/favicon.svg"
mkdir -p "$OUT/images/logos"
cp images/logos/* "$OUT/images/logos/"
[ -f "$SRC/favicon-32.png" ] && cp "$SRC/favicon-32.png" "$OUT/"
[ -f "$SRC/apple-touch-icon.png" ] && cp "$SRC/apple-touch-icon.png" "$OUT/"
touch "$OUT/.nojekyll"

esc() { sed -e 's/&/\&amp;/g' -e 's/"/\&quot;/g' -e 's/</\&lt;/g' <<<"$1"; }

# Convert root-relative links (/x/) to relative ones for the given depth; mark the active nav item.
relink() { # file base root_href active
  local file="$1" base="$2" root="$3" active="$4"
  sed \
    -e "s|href=\"$active\"|href=\"$active\" aria-current=\"page\"|g" \
    -e "s|href=\"/\"|href=\"${root}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${base}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${base}\1\"|g" \
    "$file"
}

webpage_schema() { # slug title crumb desc
  local url="$DOMAIN/$1/"
  cat <<JSON
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "WebPage",
      "name": "$2",
      "description": "$4",
      "url": "$url",
      "inLanguage": "ru-RU",
      "dateModified": "2026-10-20",
      "isPartOf": { "@type": "WebSite", "name": "Red Team Rating", "url": "$DOMAIN/" },
      "publisher": { "@type": "Organization", "name": "Red Team Rating", "url": "$DOMAIN/", "email": "research@luchshie-kompanii-po-red-teaming.com" }
    },
    {
      "@type": "BreadcrumbList",
      "itemListElement": [
        { "@type": "ListItem", "position": 1, "name": "Главная", "item": "$DOMAIN/" },
        { "@type": "ListItem", "position": 2, "name": "$3", "item": "$url" }
      ]
    }
  ]
}
JSON
}

build_page() { # slug(empty=root) name title description crumb ogtype
  local slug="$1" name="$2" title="$3" desc="$4" crumb="$5" ogtype="$6"
  local base root active dest url
  if [ -z "$slug" ]; then
    base=""; root="./"; active="/"; dest="$OUT/index.html"; url="$DOMAIN/"
  else
    base="../"; root="../"; active="/$slug/"; dest="$OUT/$slug/index.html"; url="$DOMAIN/$slug/"
    mkdir -p "$OUT/$slug"
  fi

  relink "$SRC/header.html" "$base" "$root" "$active" > "$TMP/header.html"
  # Highlight "Гайды" group when a guide is active
  case "$slug" in red-team-vs-pentest|red-blue-purple-team|ai-red-teaming)
    sed -i 's|class="rtr-nav__group"|class="rtr-nav__group is-current"|' "$TMP/header.html";;
  esac
  relink "$SRC/footer.html" "$base" "$root" "$active" > "$TMP/footer.html"
  relink "$SRC/content-$name.html" "$base" "$root" "__none__" > "$TMP/content.html"

  if [ -f "$SRC/schema-$name.json" ]; then
    cp "$SRC/schema-$name.json" "$TMP/schema.json"
  else
    webpage_schema "$slug" "$title" "$crumb" "$desc" > "$TMP/schema.json"
  fi

  local t d; t="$(esc "$title")"; d="$(esc "$desc")"
  {
    echo '<!doctype html>'
    echo '<html lang="ru">'
    echo '<head>'
    echo '<meta charset="utf-8">'
    echo '<meta name="viewport" content="width=device-width, initial-scale=1">'
    echo "<title>$t</title>"
    echo "<meta name=\"description\" content=\"$d\">"
    echo '<meta name="robots" content="noindex, nofollow">'
    echo "<link rel=\"canonical\" href=\"$url\">"
    echo "<meta property=\"og:type\" content=\"$ogtype\">"
    echo "<meta property=\"og:title\" content=\"$t\">"
    echo "<meta property=\"og:description\" content=\"$d\">"
    echo "<meta property=\"og:url\" content=\"$url\">"
    echo '<meta property="og:locale" content="ru_RU">'
    echo '<meta property="og:site_name" content="Red Team Rating">'
    echo '<meta name="theme-color" content="#141417">'
    echo "<link rel=\"icon\" href=\"${base}favicon.svg\" type=\"image/svg+xml\">"
    [ -f "$OUT/favicon-32.png" ] && echo "<link rel=\"icon\" href=\"${base}favicon-32.png\" type=\"image/png\" sizes=\"32x32\">"
    [ -f "$OUT/apple-touch-icon.png" ] && echo "<link rel=\"apple-touch-icon\" href=\"${base}apple-touch-icon.png\">"
    echo "<link rel=\"preload\" href=\"${base}fonts/onest-cyrillic-400.woff2\" as=\"font\" type=\"font/woff2\" crossorigin>"
    echo "<link rel=\"preload\" href=\"${base}fonts/unbounded-cyrillic-700.woff2\" as=\"font\" type=\"font/woff2\" crossorigin>"
    echo "<link rel=\"stylesheet\" href=\"${base}assets/rtr.css\">"
    echo '<script type="application/ld+json">'
    cat "$TMP/schema.json"
    echo '</script>'
    echo "<script src=\"${base}assets/rtr.js\" defer></script>"
    echo '</head>'
    echo '<body>'
    cat "$TMP/header.html"
    echo '<main id="main">'
    cat "$TMP/content.html"
    echo '</main>'
    cat "$TMP/footer.html"
    echo '</body>'
    echo '</html>'
  } > "$dest"
  echo "built ${dest}"
}

#           slug                    name                    title                                                           description                                                                                                                                            crumb                               og
build_page ""                      glavnaya               "Лучшие компании по Red Teaming 2026: рейтинг 12 команд"        "Рейтинг 12 компаний по Red Teaming в России: сроки, формат атаки, состав отчета и цены. Что такое Red Team в ИБ, этапы и отличия от пентеста."             "Главная"                           article
build_page metodika-ocenki         metodika-ocenki        "Методика рейтинга компаний по Red Teaming: 7 критериев"        "Как мы оцениваем компании по Red Teaming: 7 критериев с весами, шкала 0-10, источники данных и расчет итогового балла из 100."                            "Методика оценки"                   website
build_page zayavka-na-uchastie     zayavka-na-uchastie    "Заявка на участие в рейтинге Red Teaming 2026"                 "Как попасть в рейтинг компаний по Red Teaming: требования к участнику, какие данные прислать и сроки рассмотрения заявки."                                "Заявка на участие"                 website
build_page ob-issledovanii         ob-issledovanii        "Об исследовании Red Team Rating: цели и принципы"              "Red Team Rating сравнивает российские компании по Red Teaming по открытым данным. Зачем создан рейтинг, кто его готовит и как он обновляется."              "Об исследовании"                   website
build_page analiticheskaya-gruppa  analiticheskaya-gruppa "Аналитическая группа Red Team Rating: роли и опыт"            "Кто готовит рейтинг компаний по Red Teaming: роли аналитиков, их зоны ответственности и порядок работы над каждым обновлением."                           "Аналитическая группа"              website
build_page terminy                 terminy                "Термины Red Teaming: 20 понятий от APT до White Team"          "Словарь Red Teaming: APT, Assumed Breach, BAS, C2, IoC, OPSEC, RoE, TTP, White Team и другие термины с короткими определениями и примерами."               "Термины Red Teaming"               website
build_page proverka-dannyh         proverka-dannyh        "Как мы проверяем данные рейтинга Red Teaming"                  "Откуда берутся данные о компаниях по Red Teaming, как аналитики проверяют каждое значение и как часто обновляется рейтинг."                              "Проверка и обновление данных"      website
build_page obratnaya-svyaz         obratnaya-svyaz        "Обратная связь: вопросы о рейтинге Red Teaming"                "Как связаться с аналитической группой Red Team Rating: вопросы о методике, исправления данных и заявки компаний. Ответ в течение 5 рабочих дней."         "Обратная связь"                    website
build_page obrabotka-dannyh        obrabotka-dannyh       "Обработка персональных данных на сайте Red Team Rating"       "Какие данные собирает сайт Red Team Rating, зачем они нужны и как их удалить. Сайт не использует формы, рекламные счетчики и сторонние cookies."           "Обработка данных"                  website
build_page red-team-vs-pentest     red-team-vs-pentest    "Red Team vs пентест: 6 отличий и что выбрать в 2026"           "Пентест ищет уязвимости, Red Team проверяет, остановит ли защита атаку. Сравнение по цели, срокам, результату и цене, порядок выбора."                    "Red Team vs пентест"               article
build_page red-blue-purple-team    red-blue-purple-team   "Red, Blue и Purple Team: роли команд в ИБ 2026"                "Red Team атакует, Blue Team защищает, Purple Team объединяет их для разбора. Роли, задачи, инструменты команд и место White Team в учениях."               "Red Team, Blue Team и Purple Team" article
build_page ai-red-teaming          ai-red-teaming         "AI Red Teaming: проверка LLM и AI-агентов 2026"                "AI Red Teaming ищет способы заставить LLM нарушить правила: prompt injection, утечку промпта, чрезмерные полномочия агентов. Риски OWASP и MITRE ATLAS."  "AI Red Teaming"                    article

# robots.txt + sitemap.xml (noindex on stage 1 is intentional; sitemap is prepared ahead)
cat > "$OUT/robots.txt" <<TXT
User-agent: *
Allow: /

Sitemap: $DOMAIN/sitemap.xml
TXT

{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
  for p in "" metodika-ocenki/ zayavka-na-uchastie/ ob-issledovanii/ analiticheskaya-gruppa/ terminy/ proverka-dannyh/ obratnaya-svyaz/ obrabotka-dannyh/ red-team-vs-pentest/ red-blue-purple-team/ ai-red-teaming/; do
    echo "  <url><loc>$DOMAIN/$p</loc><lastmod>2026-10-20</lastmod></url>"
  done
  echo '</urlset>'
} > "$OUT/sitemap.xml"

echo "done: $(find "$OUT" -name index.html | wc -l) pages"
