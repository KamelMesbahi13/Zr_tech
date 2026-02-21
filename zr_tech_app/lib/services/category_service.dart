import 'package:firebase_database/firebase_database.dart';
import '../models/category_model.dart';

class CategoryService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Fetch categories for a specific shopping type (gros or detail).
  Future<List<CategoryModel>> getCategories(String shoppingType) async {
    final snapshot = await _dbRef.child('categories').child(shoppingType).get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final categories = <CategoryModel>[];

    data.forEach((key, value) {
      categories.add(
        CategoryModel.fromMap(key, Map<String, dynamic>.from(value as Map)),
      );
    });

    // Sort by order
    categories.sort((a, b) => a.order.compareTo(b.order));
    return categories;
  }

  /// Generate the next category ID (cat_XXX format).
  Future<String> _getNextCategoryId(String shoppingType) async {
    final snapshot = await _dbRef.child('categories').child(shoppingType).get();
    int maxNum = 0;

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (final key in data.keys) {
        // Extract number from cat_XXX
        final match = RegExp(r'cat_(\d+)').firstMatch(key);
        if (match != null) {
          final num = int.tryParse(match.group(1)!) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }
    }

    final nextNum = maxNum + 1;
    return 'cat_${nextNum.toString().padLeft(3, '0')}';
  }

  /// Add a new category to one or both shopping types.
  Future<void> addCategory({
    required String name,
    required String image,
    required int order,
    required List<String> types, // ['gros'], ['detail'], or ['gros', 'detail']
  }) async {
    for (final type in types) {
      final catId = await _getNextCategoryId(type);
      await _dbRef.child('categories').child(type).child(catId).set({
        'name': name,
        'image': image,
        'order': order,
      });
    }
  }

  /// Update an existing category.
  Future<void> updateCategory({
    required String shoppingType,
    required String categoryId,
    required String name,
    required String image,
    required int order,
  }) async {
    await _dbRef.child('categories').child(shoppingType).child(categoryId).update({
      'name': name,
      'image': image,
      'order': order,
    });
  }

  /// Delete a category.
  Future<void> deleteCategory({
    required String shoppingType,
    required String categoryId,
  }) async {
    await _dbRef.child('categories').child(shoppingType).child(categoryId).remove();
  }

  /// Seed initial categories into the database.
  /// Call this once to populate the database with the hardcoded data.
  Future<void> seedCategories() async {
    final categories = [
      {'name': 'كابلات', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuB-pnanfgsRJ5BIbYazJJOKbNOnNrsxUyPwrl-w2C8SAu_Bk_ItGS3l5l1S1Io65YAnHQKJAlAEsVrZB4zrerg7qGOeBciMA-6wuPL2JEZmgTD8fQsuHPWyORqK-5nkKFEuPmnapCdIvXNGF0npLvRZek4pQ19GRJw4Pv15gkhClKoumDffuo2Fy3IIpxjCTfcpF8_ENb2yvk6G8hidRR_LZa0eKr2sJv4f_8fr-rfh8a0fC3ucYbe6mtpeXxPHRYwl-5A0bbuNSPa4'},
      {'name': 'شواحن', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDeNiB1DjysNW3AJGscjFY16A8Yp5nw67mOVa3TtD1aK6DJ3-6-duUC1addJ-0WGP-6FzHglbzZPPH9XPPqhYdUgHIA45dxFxamMMJhTY4GU7AU-YPmas_m--mi1MY8fvQU9AWVxO0BdYki_ewaxoM4S56TtHJWt6Az1l-LIB-tEUUBCuhRO20uXlsJmaMO0CZWhi89qz-LceQxmQdfbzhHh2R56FLwyGVrgWkVGW2IkFw9W1tTZhZSs321UtqWEiHKYgzN3iP71kBz'},
      {'name': 'سماعات', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAkgTHrVRzR4sHh38G57yo3ykt_uCkWhnmqWQ5AldNRJ7w3grsegAKGCrY2VP1G7QfC_rfS2EV_9eL91wpVnvTAA1gRsUh5oaTFXj-JFnF6-6yJJ9-vB2M3gKu-X0Gvzr5rFRzYITcEs2dsx7c8g0CAdDa8pSb5H23sDrpewfq9PtJ1EjMwnytewG2lOCAHXI8rkXWCPhmCw4_Yh5A447Jcw4tS1Wb1eVYTJIU2tGgV5oW0p9EbL9eQdo-wFvzBc5REoehQjVk9hGc4'},
      {'name': 'أغطية', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAUofJbRF__XXX9LflKoUCj5FfwYRjIviKIn6o7jEsrE4WzpLmKqVJ4FeF63IAIW1JH0nqytHBtQEPEGt6tZ1qZY2uL7C1ILJdpJDMCMqv3mxgUgNITKsuh-3A43uxEr3MPN8eC4YcthWhIL4jtf5KDRHku--saITIwCjDCLx_VHJpw_SnOELAiDSg9F6vN5ZshiYtWovbSdkpJOkGo9ErlAQeu8K-nft-AibPo7utOn2kLqFNzLBaZmhLKZ303i2-zmG3VPtoSsNxM'},
      {'name': 'حوامل', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBavybtOOX-B9nIAXk-oJs4JgHjk45eP7SvHlUOySrPkASdt8hheD7SxUtf6QTuYHu-8axCEKsEPfgW1TUQ09ofpDJQbobFrMYaf2FDcQhxgrhbmEj8v0a3hUQFhTf4Si_ou5TsesR_N4bEujz98SiTL25QsqVlVG5Ba9b2uyuqkf0aOvE1AxrMpF8Y6S4yYlO-HMufpMjaWvTHHsvb-ol7PMOd1rkezfqXSV75ElQ-hFsPWgULSBhgXKE4GaCmAX9iEtl9bEvask0i'},
      {'name': 'بطاريات', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCYjs0Zvq2e9sC78ZkmB_8BqimL-DWWVGaGOC6-ai7Lo3DAuy3ln5wv7TUKupDgWz9T1LD746a0n4JQ1vSbnUyhc3Gw_UIrYbcuzjzAY18YJ1SGQOqf62OzF1QuKeeW6mDnjApN_AIWycEOpbcv_q1DDoNjUq4pGPr575QWkgxxibOmbAAfehHBOoLC5lWhhkucoPEEP23gqiJwZpqPmi1ypad-GkntUBRRcdNyMMV4DJ5aDte9jkMc1Go-53heP5i3w8SorQTOCns8'},
      {'name': 'حماية', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCWO4Ob24PlaqV-rnUu-7-Rf5HvuUt7hhNE6oyUVmwRjvD97L1J7Sq5Wxln1W5SnH8rTQNyVnmPDIyYTCzXf0Gco__OkBXhIznO5D0sfQpp7kgOL0romEme4BAHYEXuQgMycFGy2EiSLkjseFA0F48Cwwph45rI_LIXMMgxkU2f52vcByJ7hqD1jU63pPIU_Upml2z2x9ChuyLDGpvAqZMaYo8FOwz0SGQHoq0IFTCk0DknWIcoYUx6HhzatAIVvB3M8l73g7PaRfDI'},
      {'name': 'أدوات', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBxBAnMac1DEOdbTZFKvVvJwpzVcZLwyDWd1Q5qEOdw6YAX_Gz7prNPOLwFYPlswkhAseHSt0n_uFk2MPxh2yEzkA6JlHN4ujUccBBGUUqB7YzYwpnZ_vuVwfs8v6_Tvyb--y5WFCGR4hgqsKuPnQ-Rq_-B8jGE8hJzm8-DOqpjKoH8Noww3W644AwPVIg1EyVBrwo9p6Uxg7U3_kpodTYFSc3GbnRSXEgOLmJHndFrMToS89Nj89WzAL6AxB5RmiD3Nm4WNglXQrQ9'},
      {'name': 'ساعات', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDKd3Tc45PydtCLSBbtnjgItkedHB0DjEkj480neapLbF-wV6QNve91rtbenMnLyP1nfuxPj4OxbcizxKQOc1noq6GTTs48QrOOpVeZdaGmsWLhqlQK7pLwhvEtKETSkVix75OttNGRz_fukRL4MNbrCGtUVsY1ZkaP3yIYaKs5NmCSSe5lnfk6g4-NPSXS-Ki4MdjVNhHlM_oml3_dtXAsrMvvvTgj9PoHQSRkFdcY_vKcqiNUMsiP2ZPHDnbcreYNAsDrh5bDOeYZ'},
      {'name': 'مكبرات', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuA_4Em5Kl6ytUTbec_rksxCZ17fqpT5gLw6WQ3U9NDTyKTizGdr56v4NXdm2iZNSKPPJ0HH-qqZ3yj5-mbkEXbGJjwyf7S8dHPmg2ka1YNT8EQ8oIvBPXRtzPh5xe22D3-vQagwg2uLkYxsXOFrmd65BFAHc5sEqIDGfMobpdR_h7ag5CefOkJmhysZ8SRaUPs-kN1tC_xp_I91ZgnUcOuuknuC-SQIwk7JPN0aGUAQdOtpscX4Jq3pzwwzazvtAG3lvxS1_L4QmleM'},
      {'name': 'لوحات', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDnrZGwx1ORl-cqK1NhLnPfspbknFYjXb7tAQVWV8DHylIQjYA1Z1FwDqUn4LXD7r8YrfHKe_j6qCM5Jj87vrCiJYFGzxEIFYSJIrepfnLs4Be7u4ZzsI8dzlhsspBZFUYSXtFfQzNpWbA4vGeE_6l6JVE_P6lnJGXW6uKQzdwh_qcQ24qkH6p-jhkp1oxOdIXJwGDNYMEHH7tUokRHxPBG8kPVzJ3Y60zz6lKJUqCCQRXyj8I-WjQ_i_Qd9PB899CM5fI48l5DfIm7'},
      {'name': 'فأرات', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDXO8Vj0Jty8AgyFNudi4q9OdwaCiCRRfDJNZo7g153umXx0C8jU_1moENJgY3DM9egdEihUFGnN5Bn9pjqSDKgz3Gb2iXVMot-eGBTRsi2XoqCYXJdRkmI64hBBx2u5wZRqzhYY0oEjp0ibCXOACBnzbckgpPuR8vq0lM_b-7VADjMQxWtNAOotr3k-QThpgWHZJVLJJyul1fe3ug6mY4ZoeU8kWAn39mLWVdqoZR9B-TIsXnxKCsVUOrs3K2raIm8ZUNscov0PvYz'},
      {'name': 'حقائب', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCBorlIOAotXfmvjOkxLhDCvB67uRk3710Var4oyUPbzjUimNc5GXNraHu105JJ_Smi03QKn1iAt-x49M0D7BXX6MbIP9O2vSvYQ8ACbBBQD9nDlSrFiblivsy8OWvJLiuON0yc8Vbo-HDN4FVc2PzDeBaUckTBF-imqF_UOnSSvDc8RQ2Ac0UkJt6nejYxVAAyXYQeASEIHnC65jNvrZO2U3vbMiHIVG4Ki-UI04WHVazb-b3iFLYb0NLTzqXuMmlYjq-9JdIkXEIi'},
      {'name': 'كاميرات', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDaW0w_traxeZBNiEL56hwEZITVOPhIWX5wd3_Afa9C46Eoo0524SWc8LXzGYSAUyQSEdtilMIlWXfZzPofo1TIwZq-x2_nr885iQMQ1Zi39ki1onfFhjclP-yl0Byp7_9EvZkH1qJ-ZWrTyV0qS22LjlkhoE-5xlutJIRVt6FJvEfXyctiNe6Uq6J7RQm27vvniuVewFjYb_OWe7BbFxtnrpNXmPg4Ac3VhN60u91tpPMU2xXPYiwwWo8lnoNfmyJ_sBhHDFEuHcYY'},
      {'name': 'ألعاب', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDqFrf-dWm3wuR6b8bTEE5MaUgPLZNU79jKvbBqfA9FETzlcRlLpdSDuAaueBfuU9lBynQFb7unn0C9TmH6DOn4PAxsr8CWWnbJpgd1UffU8znxPUF1pBv85aXEyqHF9C1GB6C0gAxRwc9UoOB6-bOeaYgV-C3yos8edgprc4FecyB5U8KT3nZ79O23A564kaAM2QaZMSvu2qM10mhlh8M4NWvs7VnyPAfrfvUGQ6kJP8R2tOYHha5h6vx8s6dAXUz0ugkoH6AFdNbp'},
      {'name': 'شبكات', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuD4ZWsVKq_nF3woZx9poHTXTTtb3rnUzjpOvVWK9luPxOSnfa7UX3NV4akVVtPsTMjkmF_LgxgMW4GNjMUAP-njlL42ZPM0M5i8c2cJOWzGJl5jje2PxEm2mQAlSjmOiRjv6xnnXdbu5XS0i4kL4C4nV6S13XHe-Io0p7Lq7ROGmPibnmqNXKER9imxc2c974Q6PmYc9Wa1kcllCSVpsvFwBkKuS4-GFG3E1FHvyvZqoLewpgtDeTigEc8mk1bd_LN4m9vN4HtqO2ir'},
      {'name': 'طابعات', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuB9H8JrzEXRDtotdkOl7G4RWCPubWQ-qjMsRH8SCcSZ1nnS5bQqYWhX0oTssp__WUM9L7AqRhlzy5lh1wXXrnHx6eUca8GXCuRTUZu67VxoDu6VFrDPcWuGWLIXeB_cgSytNAGqbUgGnf-nuXZB279zqFopSkxdfMlB8PO3zNHKZSAOMKEVgFgOgcY0ZhkHsflrQWAWeINbe26hiCgXhFSG3xisXPOKlP6Y5hUii5O5u3AdS25eeOrwmOZ11Rslv-hdvCgQxKAJsAjg'},
      {'name': 'تخزين', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAcq_1TeMjWepBNPTeF4hCt06MmrRwCpolgJwlFbUI5hA1XG_TrYp5ksApp2R8MosPFV6xmp9ZKQbaGLZ9te8Hth-DQ67kz1jrFMX4MoEOKwtbi2neBLGJbC6sdYCMjhfZIe-Pjnc6lk9z3HEto5Dftqy9lmfVoRffzVm7JML7eUWctGDskA3RHpED9hmAz2aMBKnDbUCnGIfoTCQgp0bouOy0YvrfHnCYZzc9XQd0d5mW3RZl5FvQtdfniqOsAIyOy4wxaBO8y7u6z'},
      {'name': 'لوحات مفاتيح', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBY4pbr8WEPuibm-4MR7jASMtkE9WtjwAH5N2nQR_0Ud9QtFRN2WS7xKGl1wetSN3jlz9vI1Ca1Qiz042_OOyDqDdG-IXDVZSe3xMusK2gsWjCRPfc_GvwWMEULVhWm1cxqY9MzL_8rKzfDrNh0u32sx7946WGW4nt8M2QR2_UCZozBvNzuzvLNhRdV4JHTXs2d5YRqYmeAFhWGtoZ3ZfbWXTardsJP6M-E7__LZqhrb33mHBjtDdvplxKbrixPYFIZzxnJ2XiPfO8L'},
      {'name': 'درون', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCEXFowCkdqBuKrqDmxyzu_ZR7ieB8jGxil2wJGz0z5D6UQh1oJH4or4mwV8mTU6QRJGvMGAzA63c5RRpInkIVf8A_cC6DFE6eq3H6aHjloiiQzmvazesPtNT0weJT-uZdkvwMtfDEyGHp_LdxH6LFm1xjqyTLh1kFtwwlMHmneI0cKdw2ZoSqDmeDesFgOFgi0_JRAVmJAGC3Uj61ZqAl3H0kWDpba_MLlBIYYWrB1jUt39AFD4nb7hL4daIuflE9rnHnMN0zEh5lg'},
    ];

    // Seed the same categories for both gros and detail
    for (final type in ['gros', 'detail']) {
      for (int i = 0; i < categories.length; i++) {
        final catId = 'cat_${(i + 1).toString().padLeft(3, '0')}';
        await _dbRef.child('categories').child(type).child(catId).set({
          'name': categories[i]['name'],
          'image': categories[i]['image'],
          'order': i + 1,
        });
      }
    }
  }
}
