'use strict';
const express = require('express');
const PORT = 8888;
const HOST = '0.0.0.0';

const app = express();
app.get('/', (req, res) => {
  res.sendFile(__dirname + '/index.html');
});

app.listen(PORT, HOST, () => {
  console.log(`Running on http://${HOST}:${PORT}`);
});