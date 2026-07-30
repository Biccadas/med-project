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
