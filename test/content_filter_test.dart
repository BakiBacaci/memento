import 'package:flutter_test/flutter_test.dart';
import 'package:memento/utils/content_filter.dart';

void main() {
  test('uygunsuz kelimeleri yakalar', () {
    expect(ContentFilter.isObjectionable('siktir git'), isTrue);
    expect(ContentFilter.isObjectionable('What the FUCK'), isTrue);
    expect(ContentFilter.isObjectionable('sen bir orospu'), isTrue);
  });
  test('masum metinlere takılmaz', () {
    expect(ContentFilter.isObjectionable('Sabrın sonu selamettir.'), isFalse);
    expect(ContentFilter.isObjectionable('Göte değil, gönüle bak.'), isFalse);
    expect(ContentFilter.isObjectionable('Picasso harika bir ressamdı'), isFalse);
    expect(ContentFilter.isObjectionable('Shitake mantarı'), isFalse);
    expect(ContentFilter.isObjectionable('aquarium'), isFalse);
  });
}
