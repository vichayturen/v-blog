echo "git committing and pushing..."
git add .
git commit -m "update blogs."
git push
echo "synchronizing with server..."
scp -r ./src/.vuepress/dist/* root@8.138.83.128:/usr/local/nginx/html/
echo "done."