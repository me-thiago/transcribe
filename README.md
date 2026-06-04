# transcribe

Transcreve áudio e vídeo via [ElevenLabs Scribe](https://elevenlabs.io/) — **diarizado** (separa falantes), com timestamps, em português por padrão. Um comando de shell, self-contained.

Feito pra transcrever reuniões, recados de voz e gravações de tela — local ou direto de uma máquina remota via SSH.

```bash
transcribe reuniao.mp4
  → reuniao.transcricao/
      ├── reuniao.md     # "Falante 1 [00:03:21]: ..."
      ├── reuniao.txt    # texto corrido
      └── reuniao.json   # resposta bruta da ElevenLabs
```

## Pré-requisitos (macOS)

- **`ELEVENLABS_API_KEY`** — sua chave da ElevenLabs (cada pessoa usa a sua)
- **`jq`** — `brew install jq`
- **`ffmpeg`** — `brew install ffmpeg` (só necessário pra vídeo ou áudio grande)
- `curl` e `ssh` já vêm no macOS

## Instalação

```bash
git clone <url-deste-repo> transcribe
cd transcribe
./install.sh
```

O `install.sh` cria um symlink em `~/.local/bin/transcribe`, checa as dependências e gera um template de config. Garanta que `~/.local/bin` está no seu `PATH` (no `~/.zshrc`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Configuração da chave

Cada pessoa põe a **própria** `ELEVENLABS_API_KEY`, de uma das formas (a chave **nunca** entra no repositório):

```bash
# opção A — variável de ambiente (ex: no ~/.zshrc)
export ELEVENLABS_API_KEY=sk_sua_chave

# opção B — arquivo de config (o install.sh cria o template vazio)
echo 'ELEVENLABS_API_KEY=sk_sua_chave' > ~/.config/transcribe/env
chmod 600 ~/.config/transcribe/env
```

## Uso

```bash
transcribe reuniao.mp4                      # vídeo local → extrai o áudio e transcreve
transcribe nota.m4a                         # áudio pequeno → envia direto
transcribe macmini:~/Downloads/call.webm    # arquivo remoto → stream via SSH
transcribe call.mp4 en                      # força inglês (padrão: pt; "auto" detecta)
transcribe reuniao.mp4 -o ~/Transcricoes    # escolhe onde criar a subpasta
transcribe --help
```

### Saída

Sempre cria a subpasta `<nome>.transcricao/` (ao lado do arquivo; no diretório atual se remoto; ou dentro de `-o <pasta>`):

| arquivo | conteúdo |
|---|---|
| `<nome>.md` | diarizado, com timestamps por trecho |
| `<nome>.txt` | texto corrido |
| `<nome>.json` | resposta bruta da ElevenLabs (timing palavra-a-palavra) |

## Como funciona

1. **Vídeo / áudio grande / remoto** → o `ffmpeg` extrai e comprime só o áudio pra Opus mono (um vídeo de 1.7 GB vira ~40 MB; o vídeo é descartado). **Áudio pequeno local** → envia direto, sem ffmpeg.
2. Envia pro endpoint `/v1/speech-to-text` da ElevenLabs (`model_id=scribe_v2`, `diarize=true`, idioma configurável).
3. Formata o JSON num transcript diarizado e legível (via `jq`), agrupando por falante.

Limites do Scribe: até **3 GB** de arquivo e **10 horas** de áudio — uma reunião inteira cabe num único request (a diarização não é consistente entre pedaços, então o arquivo nunca é picotado).

## Notas

- Testado em macOS / Apple Silicon. Em Linux, troque `stat -f%z` por `stat -c%s` no script.
- Arquivos remotos usam a sintaxe `host:caminho` (estilo `scp`); o `host` precisa estar no seu `~/.ssh/config`.
