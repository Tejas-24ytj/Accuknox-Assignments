#!/usr/bin/env bash

SRVPORT=4499
RSPFILE=response

rm -f $RSPFILE
mkfifo $RSPFILE

get_api() {
	read line
	echo $line
}

handleRequest() {
    # 1) Process the request
	get_api
	mod=`fortune`

cat <<EOF > $RSPFILE
HTTP/1.1 200
Content-Type: text/html

<!DOCTYPE html>
<html>
<head>
    <title>Wisecow - Kubernetes Deployment</title>
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            font-family: 'Courier New', monospace;
            color: white;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: rgba(0,0,0,0.3);
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #FFD700;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
            margin: 0;
        }
        .header h2 {
            color: #87CEEB;
            font-size: 1.5em;
            margin: 10px 0;
        }
        .k8s-info {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin: 30px 0;
        }
        .k8s-section {
            background: rgba(255,255,255,0.1);
            border-radius: 10px;
            padding: 20px;
            border-left: 5px solid;
        }
        .pods { border-left-color: #FF6B6B; }
        .services { border-left-color: #4ECDC4; }
        .deployments { border-left-color: #45B7D1; }
        .ingress { border-left-color: #96CEB4; }
        .k8s-section h3 {
            margin-top: 0;
            font-size: 1.3em;
        }
        .pods h3 { color: #FF6B6B; }
        .services h3 { color: #4ECDC4; }
        .deployments h3 { color: #45B7D1; }
        .ingress h3 { color: #96CEB4; }
        .k8s-section ul {
            list-style: none;
            padding: 0;
        }
        .k8s-section li {
            padding: 5px 0;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        .k8s-section li:last-child {
            border-bottom: none;
        }
        .fortune-section {
            background: rgba(0,0,0,0.4);
            border-radius: 10px;
            padding: 20px;
            margin: 30px 0;
            border: 2px solid #FFD700;
        }
        .fortune-section h3 {
            color: #FFD700;
            text-align: center;
            margin-top: 0;
        }
        pre {
            color: #98FB98;
            font-size: 0.9em;
            line-height: 1.2;
            overflow-x: auto;
        }
        .tech-stack {
            display: flex;
            justify-content: space-around;
            flex-wrap: wrap;
            margin: 20px 0;
        }
        .tech-item {
            background: rgba(255,255,255,0.2);
            padding: 10px 20px;
            border-radius: 25px;
            margin: 5px;
            font-weight: bold;
        }
        .docker { background: rgba(0,123,255,0.3); }
        .kubernetes { background: rgba(40,167,69,0.3); }
        .aws { background: rgba(255,193,7,0.3); }
        .github { background: rgba(108,117,125,0.3); }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🐄 Wisecow Kubernetes Deployment 🐄</h1>
            <h2><b>Submission by Tejas Lamkhade</b></h2>
            <div class="tech-stack">
                <span class="tech-item docker">🐳 Docker</span>
                <span class="tech-item kubernetes">☸️ Kubernetes</span>
                <span class="tech-item aws">☁️ AWS EKS</span>
                <span class="tech-item github">🚀 GitHub Actions</span>
            </div>
        </div>
        
        <div class="k8s-info">
            <div class="k8s-section pods">
                <h3>🚀 Pods</h3>
                <ul>
                    <li>• Replicas: 2</li>
                    <li>• Image: tejas24l/wisecow-tejas</li>
                    <li>• Port: 4499</li>
                    <li>• Resources: 64Mi-128Mi RAM</li>
                    <li>• CPU: 50m-100m</li>
                </ul>
            </div>
            
            <div class="k8s-section services">
                <h3>🔗 Services</h3>
                <ul>
                    <li>• Type: ClusterIP</li>
                    <li>• Port: 80 → 4499</li>
                    <li>• Selector: app=wisecow</li>
                    <li>• Namespace: wisecow</li>
                </ul>
            </div>
            
            <div class="k8s-section deployments">
                <h3>📦 Deployment</h3>
                <ul>
                    <li>• Strategy: RollingUpdate</li>
                    <li>• ImagePullPolicy: Always</li>
                    <li>• Labels: app=wisecow</li>
                    <li>• Namespace: wisecow</li>
                </ul>
            </div>
            
            <div class="k8s-section ingress">
                <h3>🌐 Ingress</h3>
                <ul>
                    <li>• Class: nginx</li>
                    <li>• TLS: cert-manager</li>
                    <li>• Host: tejaslamkhade.xyz</li>
                    <li>• SSL: Self-signed</li>
                </ul>
            </div>
        </div>
        
        <div class="fortune-section">
            <h3>🔮 Daily Wisdom</h3>
            <pre>`cowsay $mod`</pre>
        </div>
        
        <div style="text-align: center; margin-top: 30px; color: #87CEEB;">
            <p>🎯 <strong>Deployed on AWS EKS</strong> | 🔄 <strong>CI/CD with GitHub Actions</strong> | 🔒 <strong>HTTPS Enabled</strong></p>
            <p>📧 Contact: tblamkhade24@gmail.com | 🌐 Domain: tejaslamkhade.xyz</p>
        </div>
    </div>
</body>
</html>
EOF
}

prerequisites() {
	command -v cowsay >/dev/null 2>&1 &&
	command -v fortune >/dev/null 2>&1 || 
		{ 
			echo "Install prerequisites."
			exit 1
		}
}

main() {
	prerequisites
	echo "Wisdom served on port=$SRVPORT..."

	while [ 1 ]; do
		cat $RSPFILE | nc -l $SRVPORT | handleRequest
		sleep 0.01
	done
}

main
