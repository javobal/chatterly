"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const app = (0, express_1.default)();
app.use(express_1.default.json());
//app.use(morgan('tiny'))
app.use(express_1.default.static('public'));
app.use((0, cors_1.default)());
app.get('/', (req, res) => {
    res.send('Hello World!');
});
app.listen(process.env.PORT, () => {
    console.log(`app listening at http://localhost:${process.env.PORT}`);
});
//# sourceMappingURL=index.js.map