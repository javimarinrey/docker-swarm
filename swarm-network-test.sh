#!/bin/bash

PORTS_TCP=(2377 7946)
PORTS_UDP=(7946 4789)

echo "Obteniendo nodos del cluster..."
NODES=$(docker node ls --format "{{.Hostname}}" )

declare -A IPS

echo ""
echo "Resolviendo IPs de nodos..."
for node in $NODES
do
    ip=$(getent hosts $node | awk '{ print $1 }')
    IPS[$node]=$ip
    echo "$node -> $ip"
done

echo ""
echo "========================================="
echo "TEST DE CONECTIVIDAD ENTRE NODOS"
echo "========================================="

for src in "${!IPS[@]}"
do
    echo ""
    echo "Desde nodo: $src (${IPS[$src]})"
    echo "----------------------------------"

    for dst in "${!IPS[@]}"
    do
        if [ "$src" != "$dst" ]; then

            echo ""
            echo "Destino: $dst (${IPS[$dst]})"

            for p in "${PORTS_TCP[@]}"
            do
                nc -z -w2 ${IPS[$dst]} $p >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    echo "TCP $p : OK"
                else
                    echo "TCP $p : FAIL"
                fi
            done

            for p in "${PORTS_UDP[@]}"
            do
                nc -zvu -w2 ${IPS[$dst]} $p >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    echo "UDP $p : OK"
                else
                    echo "UDP $p : CHECK"
                fi
            done

        fi
    done
done

echo ""
echo "Test completado"
