import React from "react";
import { BrowserRouter as Router, Route, Switch, Link } from "react-router-dom";
import { hot } from "react-hot-loader";

import About from "./About";
import Home from "./Home";
import NotFound from "./NotFound";
import "./App.css";

const App = () => (
  <Router>
    <React.Fragment>
      <nav>
        <Link to="/">Home</Link> | <Link to="/about">About</Link> |{" "}
        <Link to="/404">404</Link>
      </nav>
      <main>
        <Switch>
          <Route component={Home} exact path="/" />
          <Route component={About} path="/about" />
          <Route component={NotFound} />
        </Switch>
      </main>
      <footer>Footer - v0.0.5</footer>
    </React.Fragment>
  </Router>
);

export default hot(module)(App);
