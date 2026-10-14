import '../migrator.dart';

/// Todas as migrações do esquema, em ordem.
///
/// Cada migração fica no próprio arquivo (`NNNN_nome.dart`) como SQL
/// embutido, para que o executável compilado não dependa de arquivos externos.
const migrations = <Migration>[];
