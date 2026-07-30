# MedLink — Contexto de Produto

## O que é
App móvel de gestão de saúde (Flutter + Firebase) para Moçambique. Três papéis: paciente, médico, admin. Fase atual: protótipo/MVP para apresentação e aprovação, seguido de pilotos em clínicas pequenas.

## Utilizadores e contexto (isto manda em todas as decisões)
- Público com possível baixa literacia digital: hierarquia óbvia, alto contraste, texto legível, ícone SEMPRE acompanhado de etiqueta de texto.
- Dispositivos Android de gama baixa e rede fraca/intermitente: performance acima de espetáculo.
- Idioma: português (pt). Mercado: Moçambique / região lusófona africana.

## Regras de design inegociáveis
- UMA só cor de marca, usada com disciplina na ação principal de cada ecrã. Papéis diferenciam-se por uma etiqueta pequena, NÃO por repintar a app inteira (hoje está azul=paciente, verde=médico, roxo=admin — a corrigir).
- Animações curtas (≤300ms) e subtis. NADA de animação contínua, parallax ou efeitos pesados. Respeitar "reduzir movimento" do sistema.
- Alvos de toque ≥ 48dp.
- Estados sempre tratados: a carregar, vazio, erro, offline, sucesso.

## Conformidade
Dados de saúde são sensíveis (futura lei de proteção de dados de Moçambique, inspirada no RGPD). Privacidade e segurança são requisitos, não extras.

## Direção visual (linguagem base)
Referência de humor: apps de saúde premium, estilo "clean/Apple" — NÃO copiar telas específicas, usar como linguagem base.
- Base predominantemente BRANCA e cinzentos muito claros; muito espaço em branco; cartões grandes, arejados, cantos bem redondos, sombras muito suaves.
- UM acento de marca VERDE fresco (esmeralda/menta), usado com disciplina: só ação principal, estado ativo, destaque ocasional. Resto neutro.
- Estados (sucesso/aviso/perigo/info) dessaturados e em pequenas doses, nunca cores berrantes a competir.
- Tipografia com títulos grandes e leves, secundário fino e cinzento; hierarquia por tamanho e espaço, não por cor. Garantir contraste AA.
- Cada ecrã segue esta linguagem à sua maneira — a referência é o norte, não um decalque.

## Imagens (estratégia)
- A app NUNCA depende de uma imagem para funcionar ou ficar bonita. Estado por defeito: avatar de iniciais bem desenhado.
- Fotos (ex.: de médicos) são um BÓNUS opcional, carregadas por cima do avatar.
- Carregamento preguiçoso (lazy) + cache em disco para não buscar repetidamente pela rede (usar cached_network_image quando implementarmos). Placeholder/esqueleto enquanto carrega; fallback para o avatar de iniciais se falhar ou não existir.
- Servir imagens em tamanho adequado ao uso (não servir ficheiros grandes para avatares pequenos). Prioridade: leveza em Android de gama baixa e rede fraca.
