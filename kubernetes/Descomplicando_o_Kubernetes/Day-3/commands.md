kubectl rollout history deployment nginx-deployment
kubectl rollout history deployment nginx-deployment -n nginx
kubectl apply -f deployment-update-recreate.yml
kubectl rollout undo deployment nginx-deployment -n nginx
kubectl rollout history deployment/nginx-deployment -n nginx
kubectl rollout history deployment nginx-deployment -n nginx --revision 3
kubectl rollout history deployment nginx-deployment -n nginx --revision 1
kubectl rollout status deployment -n nginx nginx-deployment
kubectl rollout undo deployment 
kubectl rollout undo deployment nginx-deployment -n nginx --revision 1
kubectl rollout undo deployment/nginx-deployment -n nginx --to-revision=1