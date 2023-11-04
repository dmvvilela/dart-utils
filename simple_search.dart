import 'dart:async';
import 'dart:convert';
import 'package:dfit/models/food.model.dart';
import 'package:flutter/material.dart';
import 'package:dfit/utils/clean_string.util.dart';
import 'package:dfit/utils/combination_generator.util.dart';
import 'package:dfit/viewmodels/food.viewmodel.dart';
import 'package:dfit/models/taco_food.model.dart';

class FoodsService {
  static List<TacoFoodModel> _tacoFoodsList;

  // Esta função deve ser chamada antes de utilizar o resto da classe.
  Future<List<TacoFoodModel>> getTacoFoods(BuildContext context) async {
    if (_tacoFoodsList != null) {
      return _tacoFoodsList;
    }

    try {
      String encodedTacoFoods = await DefaultAssetBundle.of(context)
          .loadString("assets/data/taco_foods.json");

      var tacoFoodsMap = json.decode(encodedTacoFoods);

      _tacoFoodsList = (tacoFoodsMap as List)
          .map((json) => TacoFoodModel.fromJson(json))
          .toList();
    } catch (e) {
      print(e);
    }

    return _tacoFoodsList;
  }

  // --- REQUISITOS DE PESQUISA ---
  // Pesquisa deve ser capaz de encontrar termos separados, como por exemplo caso o usuário busque por
  // "frango cozido", mas na tabela apenas tem "frango coxa cozido" deve ser possível encontrá-lo.
  // Caso também busque por por exemplo "arroz branco", mas nos dados só difere-se "arroz" e "arroz integral"
  // também deve mostrá-lo mesmo sem encontrar o "branco" nos dados.
  //
  // --- ALGORITMO DE BUSCA ---
  // 1. descobre as palavras da busca canonizadas, ordena-as de acordo com o tamanho (evitar "de" etc).
  // 2. Monta strings de regex positive lookahead com as palavras encontradas (poder qlq ordem de palavras).
  // 3. Prepara para realizar o loop no "banco de dados".
  // 4. Para cada alimento.. Verifica todas as regex, adicionando em um resultado
  //    parcial de acordo com a quantidade de palavras. E se o alimento já
  //    tiver sido encontrado, continua o loop sem passar nas regex restantes.
  // 5. Adiciona todos os resultados parciais, na ordem correta (mais palavras para menos).
  //
  // --- OBSERVAÇÕES ---
  // - Retornar o Future com strong type não funciona.. (Talvez se usar casting na hora, mas por agora tá bom)
  // - Informações sobre a regex nos links:
  //   https://stackoverflow.com/questions/19896324/match-string-in-any-word-order-regex
  //   https://www.debuggex.com/r/8Uk5O1Yx3Nzur1zk
  Future searchFoods(String foodDescription) {
    Completer completer = new Completer();
    List<FoodViewModel> searchResult = new List<FoodViewModel>();
    List<List<FoodViewModel>> partialResults = new List<List<FoodViewModel>>();
    List<StringBuffer> regex = new List<StringBuffer>();
    final String searchDescription = CleanString.normalize(foodDescription);
    String dataDescription;
    final wordList = searchDescription.split(RegExp(r"(\s+)"));
    final wordCount = wordList.length;
    List<String> orderedWords;

    // Se a classe não foi inicializada ou o textfield estiver vazio.
    if (_tacoFoodsList == null ||
        CleanString.normalize(foodDescription).isEmpty) {
      completer.complete(new List<FoodViewModel>());

      return completer.future;
    }

    // todo: verificar se estiver apagando (menos caracteres do que antes.. no caso retorna, senão vai dar muito overhead).
    // todo: talvez utilizar um timer, a cada chamada do searchFoods, se o timer não tiver passado retorna.. sei lá pensar

    // É preciso reordenar as palavras de acordo com a importância delas..
    // Por exemplo, se o usuário buscar por "peito de frango", os resultados
    // que devem aparecer primeiro é de "peito" e "frango" e não "peito" "de".
    // A forma que encontrei de fazer isso foi pelo número de caracteres de cada palavra.
    orderedWords = wordList;
    orderedWords.sort((a, b) => b.length.compareTo(a.length));

    // Monta-se as strings de regex com todas as combinações possíveis de palavras sem repetição.
    var wordIndexes =
        new CombinationGenerator().getAllSetCombinations(wordCount);

    for (int i = 0; i < wordIndexes.length; i++) {
      // É prioridade aparecer os resultados que encontrem o máximo de palavras em conjunto.
      // Portanto uma lista com as listas e uma lista com as regex foram criadas em mesma quantidade.
      // Além disso o CombinationGenerator retorna os resultados mais importantes primeiro.
      var buffer = new StringBuffer();
      var list = new List<FoodViewModel>();

      // Esse modelo permite encontrar as palavras em qualquer ordem.
      // Como já temos as combinações de palavras, esse é o segundo passo do algoritmo.
      // Único problema que vejo agora é se a ordem das palavras de por exemplo "peito de frango"
      // perder prioridade em algum motivo para "peito frango", mas não enxerguei isso acontecendo.
      // Outra coisa é se o usuário não terminou de digitar.. Portanto se ele pesquisar por "peito de f"
      // vai aparecer resultado de "de f" na frente de algo que contenha "peito"..
      // Mas o dinamismo que isso implica acho que não vale a programação.
      for (int j = 0; j < wordIndexes[i].length; j++) {
        // Positive lookahead used in this circumstance to match a set of patterns in any order.
        buffer.write(
          "(?=.*" + orderedWords[wordIndexes[i][j]] + ")",
        ); // e.g. (?=.*arroz)
      }

      partialResults.add(list);
      regex.add(buffer);
    }

    // Loop no banco de dados com cada alimento. Hora de preencher a lista com os resultados.
    try {
      // Resultados serão divididos em parciais para garantir a ordem de importância ao mostrar para o usuário.
      _tacoFoodsList.forEach((food) {
        dataDescription = CleanString.normalize(food.description);

        for (int i = 0; i < regex.length; i++) {
          if (dataDescription.contains(RegExp(regex[i].toString()))) {
            // Os primeiros resultados parciais são os de maior prioridade (mais palavras).
            // todo: puxar direto Json do Firebase.. por enquanto será na mão.
            partialResults[i].add(
              FoodViewModel.fromModel(
                FoodModel()
                  ..description = food.description
                  ..energyKcal = food.energy.toDouble()
                  ..carbohydrates = food.carbohydrates.toDouble()
                  ..proteins = food.proteins.toDouble()
                  ..totalFats = food.totalFats.toDouble()
                  ..fiber = food.fiber.toDouble()
                  ..portionSize = 100.0
                  ..portionUnit = "g"
                  ..polyunsaturatedFats = food.polyunsaturated.toDouble()
                  ..saturatedFats = food.saturated.toDouble()
                  ..monounsaturatedFats = food.monounsaturated.toDouble()
                  ..cholesterol = food.cholesterol.toDouble()
                  ..calcium = food.calcium.toDouble()
                  ..magnesium = food.magnesium.toDouble()
                  ..manganese = food.manganese.toDouble()
                  ..phosphorus = food.phosphorus.toDouble()
                  ..iron = food.iron.toDouble()
                  ..sodium = food.sodium.toDouble()
                  ..potassium = food.potassium.toDouble()
                  ..copper = food.copper.toDouble()
                  ..zinc = food.zinc.toDouble()
                  ..vitaminA = food.vitaminA.toDouble()
                  ..vitaminB1 = food.vitaminB1.toDouble()
                  ..vitaminB2 = food.vitaminB2.toDouble()
                  ..vitaminB6 = food.vitaminB6.toDouble()
                  ..vitaminB3 = food.vitaminB3.toDouble()
                  ..vitaminC = food.vitaminC.toDouble(),
              ),
            );

            // Alimento encontrado, pode sair do loop.
            break;
          }
        }
      });
    } catch (e) {
      print(e);
    }

    // todo: Colocar alimentos com menor probabilidade em cor mais fraca na UI.
    partialResults.forEach((list) {
      searchResult.addAll(list);
    });

    completer.complete(searchResult);

    return completer.future;
  }

  Future<List<FoodModel>> getDbFoods(BuildContext context) async {
    return null;
  }

  // createDbFood(FoodViewModel food) {}

  // updateDbFood(var record) {
  //   Firestore.instance.runTransaction((transaction) async {
  //    final freshSnapshot = await transaction.get(record.reference);
  //    final fresh = Record.fromSnapshot(freshSnapshot);

  //    await transaction
  //        .update(record.reference, {'votes': fresh.votes + 1});
  //  }
  // }
}
