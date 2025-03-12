#!/bin/bash

# MIT License
# Copyright (c) 2025 [Seu Nome]

# Verifica se o script está sendo executado como root
if [[ $EUID -ne 0 ]]; then
  echo "Este script deve ser executado como root. Tente novamente com sudo."
  exit 1
fi

# Verifica dependências
for cmd in nmcli ip grep awk sed ping; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Erro: Comando '$cmd' não encontrado. Instale-o primeiro."
    exit 1
  fi
done

# Função principal
create_bridge() {
  clear

  echo -e "\nCriador de Rede Bridge - Sabelli Infra"
  
  # Nome da Bridge
  while true; do
    read -rp "Digite o nome para a Bridge (ex: br0): " BRIDGE_NAME
    if nmcli connection show "$BRIDGE_NAME" &>/dev/null; then
      echo "Erro: Já existe uma conexão com o nome '$BRIDGE_NAME'!"
    else
      break
    fi
  done

  # Seleção de Interface
  echo -e "\nInterfaces de Rede Disponíveis:"
  ip -o link show | awk -F': ' '{print $2}' | grep -v lo

  while true; do
    read -rp "Digite a interface física (ex: eth0): " INTERFACE
    if ip link show "$INTERFACE" &>/dev/null; then
      break
    else
      echo "Interface '$INTERFACE' não encontrada!"
    fi
  done

  # Desativar conexões existentes
  existing_conn=$(nmcli -t -g GENERAL.CONNECTION device show "$INTERFACE" 2>/dev/null)
  if [[ -n "$existing_conn" ]]; then
    echo -e "\nDesativando conexão existente: $existing_conn"
    nmcli connection down "$existing_conn" 2>/dev/null
    nmcli connection modify "$existing_conn" autoconnect no 2>/dev/null
  fi

  # Criar Bridge
  echo -e "\nCriando bridge '$BRIDGE_NAME'..."
  if ! nmcli connection add type bridge con-name "$BRIDGE_NAME" ifname "$BRIDGE_NAME" &>/dev/null; then
    echo "Erro fatal: Falha ao criar bridge!"
    exit 1
  fi

  # Adicionar Interface à Bridge
  echo "Adicionando interface '$INTERFACE'..."
  if ! nmcli connection add type bridge-slave con-name "${BRIDGE_NAME}-slave" ifname "$INTERFACE" master "$BRIDGE_NAME" &>/dev/null; then
    echo "Erro fatal: Falha ao adicionar interface!"
    exit 1
  fi

  # Ativar configurações
  echo -e "\nAtivando configurações..."
  nmcli connection up "$BRIDGE_NAME" &>/dev/null
  nmcli connection up "${BRIDGE_NAME}-slave" &>/dev/null

  # **Corrigindo problema da bridge não aparecer na GUI**
  echo -e "\nReiniciando NetworkManager para atualizar configurações..."
  systemctl restart NetworkManager

  # Resultado
  echo -e "\n\033[1;32mBridge configurada com sucesso!\033[0m"
  echo "--------------------------------"
  echo "Nome: $BRIDGE_NAME"
  echo "Interface: $INTERFACE"
  echo -e "\nSe a bridge não aparecer imediatamente, tente reiniciar o computador."
}

# Execução principal
create_bridge
