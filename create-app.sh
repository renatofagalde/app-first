#!/bin/bash

# L1: Perguntar o nome do novo repositório
echo "#L1: Perguntando o nome do novo repositório..."
read -p "Enter the name of the new GitHub repository: " repo_name

# L2: Definir o nome da stack baseado no nome do repositório
echo "#L2: Definindo o nome da stack..."
stack_name="${repo_name}-stack"

# L3: Definir o repositório original de onde os secrets serão copiados
echo "#L3: Definindo o repositório original de onde os secrets serão copiados..."
original_repo="renatofagalde/app-first"

# L4: Criar o repositório no GitHub
echo "#L4: Criando o repositório no GitHub..."
echo "Creating new repository '$repo_name' on GitHub..."
gh repo create "$repo_name" --private --confirm

# L5: Clonar o repositório original com o nome do novo repositório (pasta uma acima)
echo "#L5: Clonando o repositório original..."
cd .. || exit
git clone https://github.com/renatofagalde/app-first "$repo_name"

# L6: Substituir o nome da stack no arquivo pipeline.yaml
echo "#L6: Substituindo o nome da stack no arquivo pipeline.yaml..."
sed -i "s/TESTING_STACK_NAME: .*/TESTING_STACK_NAME: ${stack_name}/g" "$repo_name"/.github/workflows/pipeline.yaml
sed -i "s/PROD_STACK_NAME: .*/PROD_STACK_NAME: ${stack_name}/g" "$repo_name"/.github/workflows/pipeline.yaml

# L7: Substituir o nome da stack no arquivo samconfig.toml
echo "#L7: Substituindo o nome da stack no arquivo samconfig.toml..."
sed -i "s/stack_name = .*/stack_name = \"${stack_name}\"/g" "$repo_name"/samconfig.toml

# L8: Renomear o diretório do módulo para 'bootstrap'
echo "#L8: Renomeando o diretório do módulo para 'bootstrap'..."
mv "$repo_name"/hello-world "$repo_name"/bootstrap

# L9: Substituir o nome do módulo no go.mod para 'bootstrap'
echo "#L9: Substituindo o nome do módulo no go.mod para 'bootstrap'..."
sed -i "s/module .*/module bootstrap/g" "$repo_name"/bootstrap/go.mod

# L10: Atualizar o template.yaml para incluir o nome da stack no recurso da Lambda
echo "#L10: Atualizando o template.yaml para incluir o nome da stack no recurso da Lambda..."
sed -i "s/FunctionName: .*/FunctionName: ${stack_name}-lambda/g" "$repo_name"/template.yaml

# L11: Adicionar o novo repositório remoto com o nome "github"
echo "#L11: Adicionando o novo repositório remoto com o nome 'github'..."
cd "$repo_name" || exit
git remote add github https://github.com/renatofagalde/"$repo_name".git

# L12: Push inicial para o novo repositório
echo "#L12: Realizando o push inicial para o novo repositório..."
git push github main

# L13: Criar os segredos no novo repositório
echo "#L13: Criando os segredos no novo repositório..."
REPO="renatofagalde/$repo_name"  # Define o repositório no formato correto
echo "$GITHUB_AWS_ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID --repo "$REPO"  # Definindo o segredo AWS_ACCESS_KEY_ID
echo "$GITHUB_AWS_SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY --repo "$REPO"  # Definindo o segredo AWS_SECRET_ACCESS_KEY

# L14: Informar o sucesso
echo "#L14: Informando o sucesso..."
echo "Repository '$repo_name' and stack '$stack_name' created successfully with AWS secrets configured!"
