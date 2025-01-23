#!/bin/bash

# MIT License
# Copyright (c) 2025 [Seu Nome]
# 
# Permissão é concedida, gratuitamente, a qualquer pessoa que obtenha uma cópia deste software e arquivos de documentação associados
# (o "Software"), para lidar com o Software sem restrições, incluindo, sem limitação, os direitos de usar, copiar, modificar, mesclar,
# publicar, distribuir, sublicenciar e/ou vender cópias do Software, e permitir que as pessoas a quem o Software é fornecido o façam,
# sob as seguintes condições:
# 
# O aviso de copyright acima e este aviso de permissão serão incluídos em todas as cópias ou partes substanciais do Software.
# 
# O SOFTWARE É FORNECIDO "COMO ESTÁ", SEM GARANTIA DE QUALQUER TIPO, EXPRESSA OU IMPLÍCITA, INCLUINDO, MAS NÃO LIMITADA A, GARANTIAS
# DE COMERCIABILIDADE, ADEQUAÇÃO A UM DETERMINADO PROPÓSITO E NÃO VIOLAÇÃO. EM NENHUM CASO OS AUTORES OU DETENTORES DOS DIREITOS
# AUTORAIS SERÃO RESPONSÁVEIS POR QUALQUER REIVINDICAÇÃO, DANO OU OUTRA RESPONSABILIDADE, SEJA EM UMA AÇÃO DE CONTRATO, DELITO OU
# OUTRA FORMA, DECORRENTE DE, FORA DE OU EM CONEXÃO COM O SOFTWARE OU O USO OU OUTRAS NEGOCIAÇÕES NO SOFTWARE.

# Função para exibir informações sobre o projeto
function display_info() {
  echo -e "\e]8;;https://sabelliinfra.com\e\\Sabelli Infra\e]8;;\e\\ - Criador de Rede Bridge"
  echo -e "Site: \e]8;;https://sabelliinfra.com\e\\https://sabelliinfra.com\e]8;;\e\\"
  echo -e "GitHub: \e]8;;https://github.com/Sabelli-INfra/Linux-Bridge-Bash-Script\e\\https://github.com/Sabelli-INfra/Linux-Bridge-Bash-Script\e]8;;\e\\"
  echo
}

# Função para detectar o sistema operacional
function detect_os() {
  OS=$(grep '^ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
  echo "Sistema Operacional detectado: $OS"
}

# Função para listar interfaces de rede
function list_interfaces() {
  echo "Interfaces de Rede Disponíveis:"
  ip link show | grep -E "^[0-9]+:" | awk -F: '{print $2}' | sed 's/^ //g'
}

# Função para criar a rede bridge
function create_bridge() {
  # Solicitar nome da bridge
  echo -n "Digite o nome para a rede Bridge (ex: br0): "
  read BRIDGE_NAME

  # Listar interfaces e solicitar seleção
  list_interfaces
  echo -n "Digite o nome da interface que participará da Bridge (ex: eth0): "
  read INTERFACE

  # Escolher IP via DHCP ou estático
  echo "Escolha a configuração de IP para a Bridge:"
  echo "1) DHCP (Automático)"
  echo "2) Estático (Manual)"
  echo -n "Opção: "
  read IP_OPTION

  if [[ "$IP_OPTION" == "1" ]]; then
    IP_METHOD="dhcp"
  elif [[ "$IP_OPTION" == "2" ]]; then
    echo -n "Digite o endereço IP (ex: 192.168.1.100): "
    read IP_ADDR
    echo -n "Digite a máscara de rede (ex: 24): "
    read NETMASK
    echo -n "Digite o gateway (ex: 192.168.1.1): "
    read GATEWAY
    echo -n "Digite o(s) DNS (separados por vírgula, ex: 8.8.8.8,8.8.4.4): "
    read DNS
    IP_METHOD="static"
  else
    echo "Opção inválida. Saindo..."
    exit 1
  fi

  # Criar a bridge
  echo "Criando a bridge $BRIDGE_NAME..."
  nmcli connection add type bridge con-name $BRIDGE_NAME ifname $BRIDGE_NAME

  # Adicionar interface à bridge
  echo "Adicionando a interface $INTERFACE à bridge $BRIDGE_NAME..."
  nmcli connection add type bridge-slave con-name ${BRIDGE_NAME}-slave ifname $INTERFACE master $BRIDGE_NAME

  # Configurar IP
  if [[ "$IP_METHOD" == "dhcp" ]]; then
    nmcli connection modify $BRIDGE_NAME ipv4.method auto ipv6.method ignore
  else
    nmcli connection modify $BRIDGE_NAME ipv4.addresses ${IP_ADDR}/${NETMASK} ipv4.gateway $GATEWAY ipv4.dns "$DNS" ipv4.method manual
  fi

  # Ativar a bridge
  echo "Ativando a bridge $BRIDGE_NAME..."
  nmcli connection up $BRIDGE_NAME

  echo "Bridge $BRIDGE_NAME criada e ativada com sucesso!"
}

# Função para testar a conectividade
function test_connectivity() {
  echo "Testando conectividade..."
  ping -c 4 8.8.8.8
  if [[ $? -eq 0 ]]; then
    echo "Conectividade OK!"
  else
    echo "Falha na conectividade. Verifique as configurações."
  fi
}

# Programa principal
clear
display_info
detect_os
create_bridge
test_connectivity
