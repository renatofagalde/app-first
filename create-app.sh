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

# L8: Renomear o diretório do código para o nome do repositório
echo "#L8: Renomeando o diretório do código para '$repo_name'..."
mv "$repo_name"/hello-world "$repo_name/$repo_name"

# L9: Substituir o nome do módulo no go.mod para o nome do repositório
echo "#L9: Substituindo o nome do módulo no go.mod para '$repo_name'..."
sed -i "s/module .*/module $repo_name/g" "$repo_name/$repo_name/go.mod"

# L10: Atualizar o template.yaml para substituir HelloWorld pelo nome do repositório em letras minúsculas
echo "#L10: Atualizando o template.yaml para substituir HelloWorld pelo nome do repositório..."
lowercase_repo_name=$(echo "$repo_name" | tr '[:upper:]' '[:lower:]')  # Converte o nome do repositório para letras minúsculas
sed -i "s/HelloWorld/${lowercase_repo_name}/g" "$repo_name/template.yaml"  # Substitui HelloWorld pelo nome do repositório

# L11: Atualizar o template.yaml para substituir o nome da LambdaExecutionRole pelo nome da stack
echo "#L11: Atualizando o template.yaml para substituir o nome da LambdaExecutionRole..."
sed -i "s/LambdaExecutionRole/${stack_name}-LambdaExecutionRole/g" "$repo_name/template.yaml"  # Substitui o nome da role

# L12: Atualizar o template.yaml para substituir o nome da função HelloWorldFunction pelo nome do repositório
echo "#L12: Atualizando o template.yaml para substituir o nome da função..."
sed -i "s/HelloWorldFunction/${lowercase_repo_name}function/g" "$repo_name/template.yaml"  # Substitui HelloWorldFunction pelo nome do repositório

# L13: Adicionar o novo repositório remoto com o nome "github"
echo "#L13: Adicionando o novo repositório remoto com o nome 'github'..."
cd "$repo_name" || exit
git remote add github https://github.com/renatofagalde/"$repo_name".git

# L14: Push inicial para o novo repositório
echo "#L14: Realizando o push inicial para o novo repositório..."
git push github main

# L15: Criar os segredos no novo repositório
echo "#L15: Criando os segredos no novo repositório..."
REPO="renatofagalde/$repo_name"  # Define o repositório no formato correto
echo "$GITHUB_AWS_ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID --repo "$REPO"  # Definindo o segredo AWS_ACCESS_KEY_ID
echo "$GITHUB_AWS_SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY --repo "$REPO"  # Definindo o segredo AWS_SECRET_ACCESS_KEY

# L16: Informar o sucesso
echo "#L16: Informando o sucesso..."
echo "Repository '$repo_name' and stack '$stack_name' created successfully with AWS secrets configured!"
