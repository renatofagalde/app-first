##!/bin/bash

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

# L4: Clonar o repositório original com o nome do novo repositório (pasta uma acima)
echo "#L4: Clonando o repositório original..."
cd .. || exit

if git clone "$original_repo_url" "$repo_name"; then
    echo "Repositório clonado com sucesso."
    cd "$repo_name"  # Entrar fisicamente na pasta do novo repositório clonado
else
    echo "Falha ao clonar o repositório original."
    exit 1
fi

# L5: Apagar o diretório .git e reconfigurar o git com branch main
echo "#L5: Apagando o diretório .git e reconfigurando o repositório git..."
rm -rf .git


# L6: Renomear o diretório hello-world para o nome do novo repositório
echo "#L6: Renomeando o diretório hello-world para '$repo_name'..."
mv hello-world "$repo_name"

# L7: Substituir o nome da stack no arquivo pipeline.yaml
echo "#L7: Substituindo o nome da stack no arquivo pipeline.yaml..."
sed -i "s/TESTING_STACK_NAME: .*/TESTING_STACK_NAME: ${stack_name}/g" .github/workflows/pipeline.yaml
sed -i "s/PROD_STACK_NAME: .*/PROD_STACK_NAME: ${stack_name}/g" .github/workflows/pipeline.yaml

# L8: Substituir o nome da stack no arquivo samconfig.toml
echo "#L8: Substituindo o nome da stack no arquivo samconfig.toml..."
sed -i "s/stack_name = .*/stack_name = \"${stack_name}\"/g" samconfig.toml

# L9: Substituir o nome da Lambda e da LambdaExecutionRole no arquivo template.yaml
echo "#L9: Substituindo o nome da Lambda e da LambdaExecutionRole no arquivo template.yaml..."
lowercase_repo_name=$(echo "$repo_name" | tr '[:upper:]' '[:lower:]')  # Converte o nome do repositório para letras minúsculas
sed -i "s/HelloWorld/${lowercase_repo_name}/g" template.yaml
sed -i "s/HelloWorldFunction/${lowercase_repo_name}Function/g" template.yaml
sed -i "s/LambdaExecutionRole/${stack_name}-LambdaExecutionRole/g" template.yaml

# L10: Definir o nome do módulo como 'bootstrap' no go.mod
echo "#L10: Definindo o nome do módulo como 'bootstrap' no go.mod..."
sed -i "s/module .*/module bootstrap/g" "$repo_name/go.mod"

# L11: Configurar o ambiente Go
echo "#L11: Configurando o ambiente Go..."
cd "$repo_name" || exit
go mod tidy  # Executa go mod tidy para garantir que todas as dependências estejam corretas
go build -o bootstrap main.go  # Compila o código e gera o executável bootstrap
cd .. || exit

# L12: Substituir ocorrências de texto recursivamente em arquivos restantes
echo "#L12: Substituindo ocorrências de texto recursivamente..."
find . -type f -exec sed -i "s/HelloWorld/${lowercase_repo_name}/g" {} +
find . -type f -exec sed -i "s/LambdaExecutionRole/${stack_name}-LambdaExecutionRole/g" {} +
find . -type f -exec sed -i "s/HelloWorldFunction/${lowercase_repo_name}Function/g" {} +
sed -i "s|CodeUri: hello-world/|CodeUri: ${repo_name}/|g" template.yaml

# L13: Inicializar novo repositório Git e adicionar o remoto correto
echo "#L13: Inicializando novo repositório Git e adicionando o remoto correto..."
git init
git add .
git commit -m "repo inicializado"

# L15: Adicionar arquivos ao Git um por um
echo "#L15: Adicionando arquivos ao Git um por um..."
git add "$repo_name/go.mod"
git add "$repo_name/go.sum"
git add "$repo_name/main.go"
git add "$repo_name/main_test.go"
git add .

# L16: Commitar as alterações
echo "#L16: Commitando as alterações..."
git commit -m "Adicionando código e arquivos necessários."


git branch -M main
git remote add github "https://github.com/renatofagalde/$repo_name.git"

gh repo create "$repo_name" --private --confirm

# L17: Push inicial para o novo repositório
echo "#L17: Realizando o push inicial para o novo repositório..."
git push -u github main


# L14: Criar os segredos no novo repositório
echo "#L14: Criando os segredos no novo repositório..."
REPO="renatofagalde/$repo_name"  # Define o repositório no formato correto
echo "$GITHUB_AWS_ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID --repo "$REPO"  # Definindo o segredo AWS_ACCESS_KEY_ID
echo "$GITHUB_AWS_SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY --repo "$REPO"  # Definindo o segredo AWS_SECRET_ACCESS_KEY



# L18: Informar o sucesso
echo "#L18: Informando o sucesso..."
echo "Repository '$repo_name' and stack '$stack_name' created successfully with AWS secrets configured!"
