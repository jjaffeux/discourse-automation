import { module, test } from "qunit";
import { hbs } from "ember-cli-htmlbars";
import { render } from "@ember/test-helpers";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import fabricators from "discourse/plugins/discourse-automation/discourse/lib/fabricators";
import selectKit from "discourse/tests/helpers/select-kit-helper";

module("Integration | Component | da-categories-field", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.automation = fabricators.automation();
  });

  test("set value", async function (assert) {
    this.field = fabricators.field({ component: "categories" });

    await render(
      hbs`<AutomationField @automation={{this.automation}} @field={{this.field}} />`
    );

    await selectKit().expand();
    await selectKit().selectRowByValue(6);

    assert.strictEqual(this.field.metadata.value, [6]);
  });
});
