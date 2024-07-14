echo "git committing and pushing..."
git add .
git commit -m "update blogs."
git push
echo "synchronizing with server..."
scp -r ./src/.vuepress/dist/* root@192.168.1.100:/usr/local/nginx/html/
echo "done."