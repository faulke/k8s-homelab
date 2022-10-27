apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: gitlab-agent
  namespace: kube-system
spec:
  chart: gitlab-agent
  version: 1.6.0
  repo: https://charts.gitlab.io
  set:
    image.tag: v15.6.0-rc1
    config.token: ${agent_token}
    config.kasAddress: wss://kas.gitlab.com
