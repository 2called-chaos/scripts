#!/usr/bin/env ruby
# Encoding: ISO-8859-1

# Amortiza��o Price  2013.10.24
# Copyright (c) 2013 Renato Silva
# Licenciado sob os termos da GNU GPLv2

# Texto de ajuda

if [ "--help", "-h", nil ].include? ARGV[0] then puts "
    Este programa calcula o andamento de um empr�stimo, feito atrav�s do
    sistema Price, baseado em amortiza��es adicionais espec�ficas. Desta forma �
    poss�vel prever como certos adiantamentos ir�o alterar o pagamento do
    empr�stimo, especialmente o qu�o antecipadamente ele poder� ser quitado.\n
Modo de usar: #{File.basename($0)} <arquivo de entrada>\n
O arquivo de entrada deve estar no seguinte formato:
    taxa: <taxa de juros>
    parcelas: <n�mero de parcelas>
    saldo: <saldo devedor inicial>
    inicio: <m�s e ano da primeira parcela no formato mm/aaaa>
    adiantamento mm/aaaa: <valor do adiantamento para este m�s e ano>\n\n"
    exit
end

# Dados de entrada

nome_do_arquivo = ARGV[0].encode(ARGV[0].encoding, 'ISO-8859-1')
parcelas, taxa, saldo = 0
adiantamentos = {}

File.readlines(nome_do_arquivo).each do |linha|
    chave, valor = linha.strip.split(":").each { |coluna| coluna.strip! }
    next if [ chave, valor ].include? nil

    chave.slice!(/adiantamento\s+/)
    valor.sub!(",", ".")
    valor.slice!("%")

    case chave.strip
        when "parcelas"       then parcelas = valor.to_i
        when "taxa"           then taxa = 1 + (valor.to_f / 100)
        when "saldo"          then saldo = valor.to_f
        when "inicio"         then $inicio = valor
        when /\d+\/\d+/       then adiantamentos[chave] = valor.to_f
    end
end

# Valor da presta��o e quita��o de acordo com os adiantamentos

class Numeric
    def moeda
        (self * 100).round.to_f / 100
    end
    def reais
        ("R$ %.2f" % self).sub(".", ",")
    end
    def data
        mes_ini, ano_ini = $inicio.split("/")
        mes_ord = self + mes_ini.to_i - 2
        ano = (mes_ord / 12) + ano_ini.to_i
        mes = (mes_ord % 12 + 1).to_s.rjust(2, "0")
        "#{mes}/#{ano}"
    end
end

amortizacao = 0
prestacao = ((saldo * (taxa - 1)) / (1 - (1 / taxa ** parcelas))).moeda
puts "#\tData\t\tSaldo devedor\tAmortizado"

(1..parcelas).each do |parcela|
    amortizacao = prestacao + (adiantamentos[parcela.data] or 0);
    saldo = (saldo * taxa).moeda

    amortizacao = saldo if amortizacao > saldo
    puts "#{parcela}\t#{parcela.data}\t\t#{saldo.reais}\t#{amortizacao.reais}"

    break if amortizacao == saldo
    saldo -= amortizacao
end

puts "\nPresta��o: #{prestacao.reais}"
puts "�ltimo adiantamento efetivo: #{(amortizacao - prestacao).reais}" if amortizacao > prestacao
