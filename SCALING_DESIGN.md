# Plano de Design — Scaling & Progressão

> Documento de design para o sistema de escalonamento de dificuldade do jogo
> (survivor / bullet-heaven em Godot 4.6). Resultado de um brainstorm; nada aqui
> está escrito na pedra. Status: **esqueleto fechado, falta detalhar upgrades e
> travar números.**

---

## ⏳ Decisões pendentes do usuário (progressão dos inimigos)

São itens de **conteúdo/ritmo**. NÃO dependem dos upgrades nem de mais nada
conceitual — podem ser decididos/ajustados a qualquer momento. Os valores abaixo
são rascunhos meus que servem de ponto de partida.

1. **Multiplicadores dos arquétipos** — confirmar/ajustar o "feel":
   `Fast: hp ×1.5, spd ×1.25` · `Tank: hp ×2.0`. (Basic = baseline ×1.)
2. **Quantos arquétipos vão existir** — hoje 3 (Basic/Fast/Tank). Planejar mais?
   (ex.: Swarm fraco e veloz, Bruiser que dá muito dano.) Define o tamanho da tabela.
3. **Tabela de composição/densidade** — em que tier cada arquétipo entra no pool e os
   números de densidade (rascunho: tiers 0→6 com densidade 10→25→40→60→80→cap 200).
4. **Cadência dos mini-bosses** — manter "a cada 8 níveis" ou mudar.

---

## 1. Objetivo

Criar uma **fórmula/diretriz única** para escalonar o jogo de forma geral, de modo
que adicionar conteúdo novo (waves, inimigos, armas, upgrades) seja só seguir um
padrão pré-determinado. A progressão deve ser **exponencial** — dano/HP na casa
das dezenas no começo, centenas/milhares no fim.

**Visão de design central (a regra de ouro):**

> O sistema NÃO controla a dificuldade — as **decisões do jogador** controlam.
> Joga bem → late game fácil. Joga mal → late game difícil.

---

## 2. O diagnóstico (por que o jogo atual parece "sem dificuldade")

O jogo hoje tem **um relógio só**: o **nível do player** dirige *tanto* o poder
*quanto* a dificuldade do mundo.

```
kills → XP → nível ↑ → (mais poder)         ┐
                    └→ (mundo mais difícil)  ┘  ← os dois sobem juntos, na mesma base
```

Como poder e dificuldade andam atrelados à mesma variável, o jogador nunca pode
"ficar pra trás" — a dificuldade só avança quando ele avança. **Não existe variável
independente criando tensão.** É por isso que é impossível "definir dificuldade":
não há eixo de tensão.

Copiar o scaling do Vampire Survivors (que pressupõe o relógio-**tempo**) não encaixa
direto, porque este jogo é **kill-based**, não time-based.

### Insight-chave

> Para a *skill* do jogador virar dificuldade, é PRECISO existir uma régua
> **externa e indiferente** às decisões dele, para essas decisões correrem contra.
> Skill só se expressa como uma **distância** entre o poder que VOCÊ construiu e
> uma régua que não liga pra você. Sem régua externa → sem distância → sem skill
> medível → o "flat" de hoje.

O relógio independente não é inimigo da visão. **Ele é o que torna a visão possível.**

---

## 3. A solução — Modelo de dois relógios

Separar o que hoje está grudado em **três eixos independentes**:

| Eixo | Dirigido por | Quem controla | Papel |
|---|---|---|---|
| **Ameaça** (HP/dano/densidade/composição) | **TEMPO** | o sistema | a régua externa indiferente |
| **Oportunidade** (quando você sobe de nível) | **kills** | o player (indireto) | ritmo de escolhas |
| **Conversão** (quanto poder extrai por escolha) | **decisões/build** | o player (direto) | **onde mora a skill** |

```
TEMPO        →  sobe a AMEAÇA (régua externa, exponencial)
NÍVEL/kills  →  te aproxima do FIM (vitória) + dá oportunidades de upgrade
MORTE        →  derrota (depende de implementar HP do player — ver §7)
```

### Por que isso entrega a visão

- **O fim NÃO é gatilho de tempo** — é o progresso do player (ver §4).
- **Joga bem → late game fácil:** mata eficiente + build sinérgica → dispara à
  frente da régua → cruza a linha com folga.
- **Joga mal → late game difícil:** mata devagar + build espalhada → a régua-tempo
  alcança → morre antes da linha.
- **Mantém a alma kill-based:** kills continuam sendo tudo (levam à vitória e dão
  poder). O tempo é só a sombra correndo atrás.
- **Não recai no "flat":** a dificuldade (tempo) é genuinamente independente do
  poder. Poder e progresso-pra-vitória podem compartilhar a base (nível) — eles
  *devem* andar juntos. O que precisava ser independente era a **dificuldade**.

---

## 4. Condição de vitória e derrota

- **Alvo de duração:** um player **bom** chega ao boss final em **~15-20 min**.
  (Essa é a âncora que calibra `g`, curva de XP e `N`.)
- **Vitória:** chegar no **nível N ≈ 100** (sensação épica, jornada longa) → spawna
  o **boss final** → vencer o boss = ganhar.
  - As **waves continuam spawnando durante a luta do boss** (adiciona desafio e
    evita o anticlímax de "boss sozinho na arena"). Tecnicamente: não pausar o
    spawner enquanto o boss existir; opcionalmente subir a densidade nesse momento
    para um clímax sufocante.
- **Derrota:** morte do player (requer implementar HP — ver §7).
- **Duração da run é EMERGENTE**, decidida pelo jogador:
  - Player deus → nível 100 em ~12 min, boss numa ameaça moderada → vitória folgada.
  - Player sofrendo → nível 100 aos ~35 min por um fio, ou morre no nível 60.
- **Bônus de pacing grátis:** como os últimos níveis (90→100) acontecem quando a
  régua-tempo está no auge, o trecho final é **naturalmente o mais tenso** — o
  clímax cai no lugar certo sem forçar.

---

## 5. Como escalonar (a "diretriz" para adicionar conteúdo)

### Princípio mestre

> Pergunte de cada coisa: **"isso é dificuldade ou é progresso?"**
> - Dificuldade (régua, indiferente a você) → **TEMPO**
> - Progresso/recompensa (sua agência) → **NÍVEL/kills**

⚠️ **Bug de design latente no código atual:** as waves hoje sobem com o **nível**
(`current_cycle = f(level)`). Isso pune o player BOM (sobe de nível rápido → enfrenta
composição pesada cedo, ainda fraco). **Mover tudo de dificuldade para o TEMPO.**

### Tudo em degraus (modelo de tier único)

Stats, densidade E composição mudam todos em **degraus discretos**, no mesmo tick,
indexados por um **único índice de tier** (= tempo / intervalo, ex.: 90s).

**Por que degraus de stat NÃO criam "cliff":** o scaling é aplicado no `_ready()`
do inimigo, ou seja, **travado no momento do spawn**. Quando o tier sobe, os
inimigos já na tela mantêm o HP com que nasceram — só os próximos spawns ganham o
boost. Como inimigos morrem/respawnam o tempo todo, a transição se dilui na
rotatividade dos spawns ao longo de alguns segundos. O degrau se dissolve sozinho.
(Só haveria cliff se reescalássemos inimigos vivos — o que NÃO fazemos.)

**Trade-off de granularidade (tuning):** degraus poucos+grandes = saltos
perceptíveis, marcos legíveis; degraus muitos+pequenos = suave, quase contínuo.
Como densidade/composição já dão os marcos perceptíveis, manter o `g` por tier
**modesto** pra o salto de stat não chamar atenção sozinho.

### O cronograma de ameaça (a tabela-diretriz)

Uma tabela só, indexada por **tier de tempo**. Adicionar conteúdo = editar uma linha.

```
tier (tempo)   mult HP/dano    densidade     pool de arquétipos
0  (0–90s)     g^0 = 1.00      10            [Basic]
1  (90–180s)   g^1             20            [Basic]
2              g^2             35            [Basic, Fast]
3              g^3             50            [Basic, Fast]
4              g^4             70            [Basic, Fast, Tank]
...            ...             ...           ...
boss           +ramp           tudo          (+ waves continuam)
```

### XP por kill = o botão da espiral (DECIDIDO: dosado, `a ≈ 0.6`)

O quão punitivo é "ficar pra trás" NÃO depende do `g` — depende de quanto XP cada
inimigo dá. Intuição (DPS-limitado, horda):

```
kills/seg = DPS / HP          XP/seg = (DPS / HP) · exp_value
```

- `exp_value` **fixo** (hoje = 1)  → XP/seg = DPS/HP → cai com a inflação → espiral MÁXIMA.
- `exp_value` **∝ HP**            → XP/seg = DPS    → constante → SEM espiral.
- `exp_value` **∝ HP^a** (0<a<1)  → espiral DOSÁVEL pelo expoente.

**Decisão: `a ≈ 0.6`** (dosado — arrasta perceptivelmente, mas recuperável).

```
exp_value = max(1, round( (max_health / 10) ^ 0.6 ))
            # 10 = HP do Basic no tier 0 → preserva "1 XP" no início
# Ex.: HP 10→1, HP 100→4, HP 1000→16, boss ~25k HP → ~110 XP
```

Isso também conserta o bug atual de `exp_value = 1` para todos (boss dava 1 XP).
O **snowball** (DPS sobe com o nível → mata mais rápido) está sempre presente; o `a`
decide o quanto a inflação de HP **briga** com ele. A corrida do final é esse cabo
de guerra.

### Inimigos como arquétipos (multiplicadores relativos ao baseline do tier)

Em vez de declarar números absolutos por inimigo, declarar **coeficientes** sobre o
baseline do tempo:

```
Tank   → hp ×2.0, speed ×0.6, dmg ×1.5
Swarm  → hp ×0.5, speed ×1.2, dmg ×0.8
Fast   → hp ×0.8, speed ×1.5, dmg ×1.0

HP real = baseHP_no_tempo(t) · arquetipo.hp_mult   → escala sozinho
```

Adicionar inimigo = escolher 3 multiplicadores. O scaling é automático.

### Fórmula de ameaça (placeholders — calibrar depois)

```
tier(t)          = floor(t / intervalo)   # t em segundos; ex.: intervalo = 90
threat_mult      = g ^ tier(t)
enemy.max_health = base_hp  · threat_mult · arquetipo.hp_mult   # travado no spawn
enemy.damage     = base_dmg · threat_mult · arquetipo.dmg_mult
```

- Para o feeling "10 → milhares": com `g ≈ 1.25` por minuto, em ~30 min o
  multiplicador chega a ~×800 (Basic de 10 HP → ~8000).
- **`g` só pode ser travado quando os upgrades forem desenhados** — ele precisa ser
  batido contra o quanto a DPS do player cresce. A dificuldade real é a **razão**
  `g_ameaça / g_player`; os dois lados precisam ser projetados juntos.

---

## 6. Upgrades — o "eixo de Conversão" (A DEFINIR — próximo passo)

Onde a skill do jogador vira dificuldade. Ainda **em aberto**, mas a direção
discutida:

- Tornar upgrades **multiplicativos e empilháveis**, **removendo o teto** atual de
  `max_level = 2` (×3). Assim o poder também é exponencial e pode acompanhar a
  ameaça exponencial.
- `Poder = base · ∏(upgrades escolhidos)` — como é um *produto* de multiplicadores
  que o player escolhe stackar, uma build focada bate multiplicadores gigantes
  (10 → milhares), enquanto uma build espalhada não acompanha. **O número grande e
  a expressão de skill saem da mesma mecânica: a profundidade da build.**
- Considerar **sinergias** entre armas/upgrades (decisões com trade-off real).

Referência: **Risk of Rain 2** — dificuldade escala com o tempo (régua), mas o
jogador decide *quando avançar vs. quando farmar*; essa decisão o deixa overpowered
ou esmagado.

---

## 7. Pendências / bugs encontrados no código atual

- **Player não tem HP / `take_damage`** → hoje é invencível. O `damage` dos inimigos
  está configurado mas **não é aplicado**. Necessário para a condição de derrota (§4).
- **`exp_value = 1` para TODOS os inimigos**, incluindo bosses de 800+ HP → XP
  desacoplado do esforço. Sugestão: `exp_value = f(HP do inimigo)`.
- **HP de boss é multiplicativo e descontínuo** (`max_health *= bonus_boss_health * 10`,
  onde `bonus_boss_health = current_level`) → saltos enormes. Sugestão: boss = múltiplo
  suave do baseline do tier (ex.: `20 · HP_normal(t)`).
- **Conteúdo congela no ciclo 6** — `waves` só tem chaves 1–6; após o ciclo 6 a wave
  não atualiza. (Resolvido naturalmente ao migrar para o cronograma-tempo infinito.)
- **Debug `f1` no `Main.gd`** chama `waves[current_cycle]` sem guard → crasha após o
  ciclo 6.
- **Typo:** `Weapons/Explosion/Explosion.gd:20` → `enemy.taka_damage` (deveria ser
  `take_damage`).

---

## 8. Esqueleto fechado — resumo

1. **Tempo** dirige stats + composição + densidade, todos em **degraus** num tier
   único (~90s). Stat travado no spawn → degrau se dilui na rotatividade (sem cliff).
2. **Nível** dirige só upgrades + gatilho do boss final.
3. **Vitória:** marco de nível → boss final; **waves continuam** durante a luta.
   **Derrota:** morte (precisa de HP do player).
4. Curva de ameaça `g^(min)`, com `g` a ser travado **junto** com o design de upgrades.

## 9. Decisões travadas (sessão 2026-06-10/11)

- Alvo: player bom → boss em **~15-20 min**.
- Marco de vitória: **nível N ≈ 100** (épico).
- Espiral **dosada**: `exp_value = max(1, round((max_health/10)^0.6))`.
- Tudo de dificuldade em degraus de tier no tempo; stat travado no spawn.
- **`g = 1.1` por tier** (provisório — rever vs DPS quando mexer nos upgrades).
  Consequência: teto de inflação fica **contido** (~×3 numa run de 15-20 min a 90s),
  abaixo do "milhares" original. Com `g` baixo, só tier mais curto infla mais.
- **Intervalo do tier = 90s** (~13 tiers numa run; composição/densidade casam 1:1
  com o tier).
- **Boss K (HP vs. inimigo normal do mesmo tier): mini ×25, final ×80.**
  `hp_boss = base_hp · g^tier · K`. Ex. no fim da run (×3.4): final ≈ 10·3.4·80 ≈ 2720 HP.

## 10. Próximos passos

1. **(Quando mexer nos upgrades)** Travar `g` por tier + intervalo do tier
   (fino ~45-60s se `g` for agressivo, p/ degrau suave) + curva de XP
   (`needed_exp`) calibrada pra `N=100` cair nos ~15-20 min de bom jogo.
2. **Comportamento do boss final** — ainda é só um "saco de HP"; falta desenhar a
   luta em si (ataques, fases). Possível próximo foco.
3. Constantes `K` dos mini-bosses e do boss final (provisórias até playtest).
4. Implementar HP do player + condição de derrota (a "morte" da §4).
5. Refatorar `wave_data.gd` e `set_props()` para o modelo data-driven por
   tempo/arquétipo (a tabela-cronograma da §5).

---

## 11. Plano de implementação (progressão dos inimigos + gancho do final)

> Escopo: SÓ a progressão dos inimigos e o esqueleto do final. **NÃO** mexe em
> armas, upgrades, nem implementa HP/derrota do player (ficam pra depois).
> **Requisito: código bem comentado** — cada arquivo explica a fórmula de ameaça,
> a referência ao modelo de dois relógios e a natureza data-driven do cronograma.

### Arquitetura

- **Relógio de run** vive no `Main`: `run_time`, `current_tier`, `threat_mult`,
  atualizados em `_process(delta)` (pausa naturalmente durante o level-up, pois nós
  pausados não processam).
- **`wave_data.gd` vira o CONFIG central** (uma fonte de verdade): constantes,
  arquétipos, cronograma, K dos bosses, nível de vitória.
- **Inimigos se auto-configuram no `_ready()`** lendo o `threat_mult` global no
  momento do spawn (= stat travado no spawn, sem cliff) + seus multiplicadores de
  arquétipo.
- **Spawner** lê o tier atual → linha do cronograma → densidade + pool de arquétipos.

### Ordem de implementação

1. `wave_data.gd` (fundação/config)
2. `Main.gd` — relógio + threat
3. `Enemies/Enemy.gd` — cálculo de stats a partir de base · threat · arquétipo
4. `Enemy1/2/3.gd` — declarar arquétipo
5. `Main.gd` — refatorar spawner (usa 1+2)
6. `Main.gd` — refatorar bosses (mini/final) + gancho de vitória
7. `Player.gd` — `level_up` (triggers) + UI

### Arquivo por arquivo

**`wave_data.gd`** — *maior mudança; vira o config central*
- REMOVER: `waves` (cycle-based) e o `bosses` dict antigo.
- ADICIONAR constantes: `GROWTH = 1.1`, `TIER_INTERVAL = 90.0`, `WIN_LEVEL = 100`,
  `MINIBOSS_EVERY = 8`, `BASE_HP = 10`, `BASE_SPEED = 60`, `BASE_DAMAGE = 10`,
  `MINIBOSS_K = 25`, `FINAL_BOSS_K = 80`. Manter `MAX_ENEMIES = 200`.
- `archetypes`: `{ "Basic": {hp_mult, speed_mult, dmg_mult, scene_key}, "Fast": {...},
  "Tank": {...} }` (Basic→Enemy1, Fast→Enemy3, Tank→Enemy2).
- `schedule`: array `[{tier, density, pool:[arquétipos]}]` (a tabela-cronograma).
- Helper `func get_schedule_row(tier)` → linha de maior `tier` <= atual.

**`Main.gd`**
- ADICIONAR `run_time`, `current_tier`, `threat_mult`; em `_process(delta)`:
  `run_time += delta`; recalcular `current_tier = int(run_time / TIER_INTERVAL)` e
  `threat_mult = pow(GROWTH, current_tier)`.
- `_on_spawn_timer_timeout`: trocar `current_wave` pela linha do cronograma do
  `current_tier` (densidade = piso, pool = tipos). Remover `health_modifier`
  (a ameaça substitui). Setar `enemy.archetype_name` antes do `add_child`.
- `spawn_boss` → dividir em `spawn_miniboss(level)` e `spawn_final_boss()`: setam
  `is_boss = true`, `boss_k` (25 ou 80) e o arquétipo; HP calculado no `Enemy`.
- `spawn_final_boss`: setar flag `final_boss_active = true` (para o ramp de
  densidade no spawner) e guardar referência pra detectar a morte.
- ADICIONAR `func on_final_boss_defeated()`: pausa + estado de vitória (por ora um
  **stub** com label "VITÓRIA"; tela final fica pra depois).
- REMOVER `go_to_next_level`, `current_cycle`, `current_wave`.
- Debug `f1`: repurpose para "pular 1 tier" (testes).

**`Enemies/Enemy.gd`**
- REMOVER `health_modifier`, `bonus_boss_health`. ADICIONAR `archetype_name`,
  `boss_k`.
- `_ready` (após `set_props()`): ler `threat = get_parent().threat_mult`; buscar
  mults em `WaveData.archetypes[archetype_name]`; calcular:
  - `max_health = round(BASE_HP * threat * hp_mult)`
  - `damage     = round(BASE_DAMAGE * threat * dmg_mult)`
  - `speed      = BASE_SPEED * speed_mult`  *(velocidade NÃO escala com threat — é
    eixo de arquétipo só; comentar essa decisão)*
  - `exp_value  = max(1, round(pow(float(max_health) / BASE_HP, 0.6)))`  *(§5: botão
    da espiral, a=0.6)*
- Se `is_boss`: `max_health = round(BASE_HP * threat * boss_k)` (sobrepõe), recalcular
  `exp_value` do HP grande, manter os ajustes visuais/dano/tamanho já existentes.

**`Enemies/Enemy1.gd` / `Enemy2.gd` / `Enemy3.gd`**
- `set_props()` deixa de cravar números; passa a só declarar o arquétipo:
  `archetype_name = "Basic"` / `"Tank"` / `"Fast"`.

**`Player.gd`**
- `level_up`: REMOVER o `% 5 → go_to_next_level`. Manter `% MINIBOSS_EVERY →
  spawn_miniboss`. ADICIONAR `if current_level == WaveData.WIN_LEVEL:
  get_parent().spawn_final_boss()`.
- `_process` UI: trocar "current cycle" por tier/tempo (ex.: `tier` e `mm:ss`).
- `get_exp` / curva de XP: **inalterada por ora** (calibra junto com `g`/upgrades).

### Notas / riscos
- **Stat travado no spawn:** ler `threat_mult` no `_ready` já garante isso (é o
  instante do spawn). Não reescalar inimigos vivos.
- **Ramp do final:** enquanto `final_boss_active`, multiplicar a densidade-alvo.
- **Colisão de triggers:** nível 100 não é múltiplo de 8, então boss final e
  mini-boss não colidem; ainda assim, guardar com `elif`.
- **Fora de escopo agora:** HP/derrota do player, comportamento do boss final
  (hoje só "saco de HP"), tela de vitória (só stub).
