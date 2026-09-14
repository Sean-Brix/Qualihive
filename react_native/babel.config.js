module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      // drizzle-kit writes migrations as .sql files; inline-import bundles
      // them so the migrator can run them on device without a filesystem read.
      ['inline-import', { extensions: ['.sql'] }],
    ],
  };
};
