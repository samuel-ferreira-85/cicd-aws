#!/bin/bash

LOG_FILE="/home/ec2-user/flask-cicd/deploy.log"
APP_DIR="/home/ec2-user/flask-cicd"

{
  echo "[$(date)] Iniciando script de deploy..."

  cd "$APP_DIR" || {
    echo "[$(date)] ERRO: diretório não encontrado: $APP_DIR"
    exit 1
  }

  echo "[$(date)] Corrigindo permissões de pasta e arquivos..."
  sudo chown -R ec2-user:ec2-user "$APP_DIR"
  sudo chown -R ec2-user:ec2-user "$LOG_FILE"

  echo "[$(date)] Instalando pip, se necessário..."
  sudo yum install -y python3-pip

  echo "[$(date)] Instalando/atualizando dependências do Python..."
  python3 -m pip install --upgrade pip
  python3 -m pip install -r requirements.txt

  echo "[$(date)] Encerrando instâncias anteriores do Flask..."
  pkill -f app.py || echo "[$(date)] Nenhuma instância ativa detectada..."

  echo "[$(date)] Iniciando aplicação Flask..."
  nohup python3 app.py > app.log 2>&1 &

  echo "[$(date)] Aguardando aplicação iniciar..."
  sleep 3

  echo "[$(date)] Verificando se a aplicação está respondendo..."
  curl -s --fail http://localhost:5000 > /dev/null

  if [ $? -ne 0 ]; then
    echo "[$(date)] ERRO: Aplicação Flask não respondeu corretamente. Desfazendo deploy."
    exit 1
  fi

  echo "[$(date)] Deploy concluído com sucesso!"
} >> "$LOG_FILE" 2>&1
