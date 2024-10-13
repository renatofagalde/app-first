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
original_repo_url="https://github.com/$original_repo"  # Variável com a URL do repositório original

# L4: Criar o repositório no GitHub
echo "#L4: Criando o repositório no GitHub..."
echo "Creating new repository '$repo_name' on GitHub..."
gh repo create "$repo_name" --private --confirm

# L5: Clonar o repositório original com o nome do novo repositório (pasta uma acima)
echo "#L5: Clonando o repositório original..."
cd .. || exit
git clone "$original_repo_url" "$repo_name"  # Usando a variável

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

# L9: Definir o nome do módulo como 'bootstrap' no go.mod
echo "#L9: Definindo o nome do módulo como 'bootstrap' no go.mod..."
sed -i "s/module .*/module bootstrap/g" "$repo_name/$repo_name/go.mod"

# L10: Configurar o ambiente Go
echo "#L10: Configurando o ambiente Go..."
cd "$repo_name/$repo_name" || exit
go mod tidy  # Executa go mod tidy para garantir que todas as dependências estejam corretas
go build -o bootstrap main.go  # Compila o código e gera o executável bootstrap

# L11: Substituir ocorrências de texto recursivamente
echo "#L11: Substituindo ocorrências de texto recursivamente..."
lowercase_repo_name=$(echo "$repo_name" | tr '[:upper:]' '[:lower:]')  # Converte o nome do repositório para letras minúsculas

find "$repo_name" -type f -exec sed -i "s/HelloWorld/${lowercase_repo_name}/g" {} +
find "$repo_name" -type f -exec sed -i "s/LambdaExecutionRole/${stack_name}-LambdaExecutionRole/g" {} +
find "$repo_name" -type f -exec sed -i "s/HelloWorldFunction/${lowercase_repo_name}function/g" {} +

# L12: Adicionar o novo repositório remoto com o nome "github"
echo "#L12: Adicionando o novo repositório remoto com o nome 'github'..."
cd "$repo_name" || exit
git remote add github "$original_repo_url"  # Usando a variável

# L13: Push inicial para o novo repositório
echo "#L13: Realizando o push inicial para o novo repositório..."
git push github main

# L14: Criar os segredos no novo repositório
echo "#L14: Criando os segredos no novo repositório..."
REPO="renatofagalde/$repo_name"  # Define o repositório no formato correto
echo "$GITHUB_AWS_ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID --repo "$REPO"  # Definindo o segredo AWS_ACCESS_KEY_ID
echo "$GITHUB_AWS_SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY --repo "$REPO"  # Definindo o segredo AWS_SECRET_ACCESS_KEY

# L15: Adicionar arquivos ao Git um por um
echo "#L15: Adicionando arquivos ao Git um por um..."
git add "$repo_name/$repo_name/go.mod"
git add "$repo_name/$repo_name/go.sum"
git add "$repo_name/$repo_name/main.go"
git add "$repo_name/$repo_name/main_test.go"

# L16: Commitar as alterações
echo "#L16: Commitando as alterações..."
git commit -m "Adicionando código e arquivos necessários."

# L17: Informar o sucesso
echo "#L17: Informando o sucesso..."
echo "Repository '$repo_name' and stack '$stack_name' created successfully with AWS secrets configured!"
