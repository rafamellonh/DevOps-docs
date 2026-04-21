### A grande ideia

## Docker = caixinha isolada para o seu app

### Analogia
```
Pense em um contêiner de navio. Não importa o que há dentro dele: roupas, eletrônicos ou comida. O navio transporta a caixa sem saber o conteúdo.
O Docker faz o mesmo com o software: empacota o app + tudo o que ele precisa em uma caixa que pode rodar em qualquer lugar.
```

Sem Docker, um app depende do sistema operacional do servidor. Com Docker, o app carrega tudo consigo: bibliotecas, configurações e a versão do Node/Python/Java. Funciona na sua máquina e no servidor do cliente exatamente da mesma forma.


![Arquitetura do Docker](img/image01.png)


## Passo 1: você digita um comando

### `docker run nginx`

### Analogia
```
Você é o cliente, e o garçom é o Docker CLI. Você faz o pedido: "Quero um Nginx". O garçom não cozinha; ele só anota o pedido e o manda para a cozinha.
```

O `Docker CLI` é só um programa que traduz seu comando em uma chamada HTTP e a envia para o `dockerd` (o daemon). Ele não faz nada sozinho.

![Passo 1](img/passo1.png)


## Passo 2: O daemon gerencia tudo

### dockerd: o gerente da cozinha

### Analogia
```
O docker é o gerente da cozinha. Ele gerencia imagens (baixa se nao tiver). redes. volumes, e politica re reinicio dos containers. Mas ele mesmo nao cria o container - organiza a rede e os volumes, e delega a cozinha para outra pessoa (containerd).

```

O `Dockerd` e o cerebro do Docker. Ele gerencia imagens (baixa se nao tiver), redes, volumes e politica de reinicio dos containers. Mas ele mesmo nao cria o container - Manda o containerd fazer isso via gRPC.  
